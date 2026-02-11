// bloc/search/search_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../repositories/document_repository.dart';
import '../../utils/error_handler.dart';
import '../../utils/exceptions.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final DocumentRepository repository;

  Timer? _debounceTimer;

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchDocuments>(_onSearchDocuments);
    on<ClearSearch>(_onClearSearch);
    on<_PerformSearch>(
      _onPerformSearch,
      transformer: restartable(),
    );
  }

  Future<void> _onSearchDocuments(
    SearchDocuments event,
    Emitter<SearchState> emit,
  ) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // If query is empty, clear search
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Debounce: schedule the actual search after 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        add(_PerformSearch(event.query));
      }
    });
  }

  Future<void> _onPerformSearch(
    _PerformSearch event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());

    try {
      final results = await repository.searchDocuments(event.query);

      if (results.isEmpty) {
        emit(SearchEmpty(event.query));
      } else {
        emit(SearchLoaded(results: results, query: event.query));
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);

      final message = e is AppException
          ? ErrorHandler.getMessage(e)
          : 'Search failed. Please try again.';
      emit(SearchError(message));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    emit(SearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

// Internal event for performing the actual search after debounce
class _PerformSearch extends SearchEvent {
  final String query;
  const _PerformSearch(this.query);

  @override
  List<Object?> get props => [query];
}
