// bloc/search/search_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/document_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final DocumentRepository repository;
  Timer? _debounce;

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchDocuments>(_onSearchDocuments);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchDocuments(
    SearchDocuments event,
    Emitter<SearchState> emit,
  ) async {
    // Cancel previous debounce timer
    _debounce?.cancel();

    // If query is empty, clear search
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Debounce search (wait 500ms before searching)
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      emit(SearchLoading());

      try {
        final results = await repository.searchDocuments(event.query);

        if (results.isEmpty) {
          emit(SearchEmpty(event.query));
        } else {
          emit(SearchLoaded(results: results, query: event.query));
        }
      } catch (e) {
        emit(SearchError('Search failed: $e'));
      }
    });
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) async {
    _debounce?.cancel();
    emit(SearchInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
