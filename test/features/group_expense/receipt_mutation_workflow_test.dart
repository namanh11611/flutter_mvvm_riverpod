import 'package:flutter_mvvm_riverpod/features/group_expense/repository/receipt_mutation_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptMutationWorkflow.remove', () {
    test('deletes Storage object before metadata', () async {
      final events = <String>[];

      await ReceiptMutationWorkflow.remove(
        objectPath: 'old',
        deleteObject: (path) async => events.add('delete:$path'),
        deleteMetadata: () async => events.add('metadata:delete'),
      );

      expect(events, ['delete:old', 'metadata:delete']);
    });

    test('does not delete metadata when Storage deletion fails', () async {
      var metadataExists = true;

      await expectLater(
        ReceiptMutationWorkflow.remove(
          objectPath: 'old',
          deleteObject: (_) async => throw StateError('storage failure'),
          deleteMetadata: () async => metadataExists = false,
        ),
        throwsStateError,
      );

      expect(metadataExists, isTrue);
    });

    test('surfaces metadata failure only after object deletion succeeds',
        () async {
      var objectExists = true;

      await expectLater(
        ReceiptMutationWorkflow.remove(
          objectPath: 'old',
          deleteObject: (_) async => objectExists = false,
          deleteMetadata: () async => throw StateError('metadata failure'),
        ),
        throwsStateError,
      );

      expect(objectExists, isFalse);
    });
  });

  group('ReceiptMutationWorkflow.replace', () {
    test('uploads, updates metadata, then cleans the old object', () async {
      final events = <String>[];

      final result = await ReceiptMutationWorkflow.replace(
        oldObjectPath: 'old',
        upload: () async {
          events.add('upload:new');
          return 'new';
        },
        updateMetadata: (path) async => events.add('metadata:$path'),
        deleteObject: (path) async => events.add('delete:$path'),
      );

      expect(result, 'new');
      expect(events, ['upload:new', 'metadata:new', 'delete:old']);
    });

    test('upload failure leaves metadata and old object unchanged', () async {
      var metadata = 'old';
      final objects = {'old'};

      await expectLater(
        ReceiptMutationWorkflow.replace(
          oldObjectPath: 'old',
          upload: () async => throw StateError('upload failure'),
          updateMetadata: (path) async => metadata = path,
          deleteObject: (path) async => objects.remove(path),
        ),
        throwsStateError,
      );

      expect(metadata, 'old');
      expect(objects, {'old'});
    });

    test('metadata failure deletes new upload and preserves old state',
        () async {
      var metadata = 'old';
      final objects = {'old', 'new'};

      await expectLater(
        ReceiptMutationWorkflow.replace(
          oldObjectPath: 'old',
          upload: () async => 'new',
          updateMetadata: (_) async => throw StateError('metadata failure'),
          deleteObject: (path) async => objects.remove(path),
        ),
        throwsStateError,
      );

      expect(metadata, 'old');
      expect(objects, {'old'});
    });

    test('old-object cleanup failure keeps metadata on valid new object',
        () async {
      var metadata = 'old';
      final objects = {'old', 'new'};

      await expectLater(
        ReceiptMutationWorkflow.replace(
          oldObjectPath: 'old',
          upload: () async => 'new',
          updateMetadata: (path) async => metadata = path,
          deleteObject: (path) async {
            if (path == 'old') throw StateError('delete failure');
            objects.remove(path);
          },
        ),
        throwsStateError,
      );

      expect(metadata, 'new');
      expect(objects, contains('new'));
    });

    test('normal replacement leaves no orphaned old object', () async {
      var metadata = 'old';
      final objects = {'old'};

      await ReceiptMutationWorkflow.replace(
        oldObjectPath: 'old',
        upload: () async {
          objects.add('new');
          return 'new';
        },
        updateMetadata: (path) async => metadata = path,
        deleteObject: (path) async => objects.remove(path),
      );

      expect(metadata, 'new');
      expect(objects, {'new'});
    });
  });
}
