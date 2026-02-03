import 'package:flutter_test/flutter_test.dart';
import 'package:khmerscan/main.dart';
import 'package:khmerscan/models/document.dart';
import 'package:khmerscan/repositories/document_repository.dart';

class FakeDocumentRepository extends DocumentRepository {
  FakeDocumentRepository() : super(dbService: null, storageService: null);

  @override
  Future<List<Document>> getAllDocuments() async => [];

  @override
  Future<List<Document>> getDocumentsPaginated({
    DateTime? cursorCreatedAt,
    int limit = 20,
  }) async =>
      [];

  @override
  Future<bool> hasMoreDocuments(DateTime cursorCreatedAt) async => false;

  @override
  Future<int> getDocumentCount() async => 0;
}

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      documentRepository: FakeDocumentRepository(),
    ));

    // Verify results
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    // Note: The app title 'KhmerLens' might be in the AppBar which is visible
    expect(find.text('KhmerLens'), findsOneWidget);
  });
}
