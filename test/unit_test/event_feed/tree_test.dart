import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/domain_layer/usecases/event_feed.dart';
import 'package:test/test.dart';

void main() {
  group('Tree', () {
    // Create a root note
    final rootNote = NostrNote(
      id: 'root123',
      pubkey: 'pubkey1',
      created_at: 1635000000,
      kind: 1,
      content: 'This is the root note.',
      sig: 'sig1',
      tags: [],
    );

    // Create replies to the root note
    final reply1 = NostrNote(
      id: 'reply1',
      pubkey: 'pubkey2',
      created_at: 1635000100,
      kind: 1,
      content: 'This is a reply to the root note.',
      sig: 'sig2',
      tags: [NostrTag(type: 'e', value: 'root123', marker: 'root')],
    );

    final reply2 = NostrNote(
      id: 'reply2',
      pubkey: 'pubkey3',
      created_at: 1635000200,
      kind: 1,
      content: 'Another reply to the root note.',
      sig: 'sig3',
      tags: [NostrTag(type: 'e', value: 'root123', marker: 'root')],
    );

    // Create replies to the replies
    final nestedReply1 = NostrNote(
      id: 'nestedReply1',
      pubkey: 'pubkey4',
      created_at: 1635000300,
      kind: 1,
      content: 'A reply to the first reply.',
      sig: 'sig4',
      tags: [
        NostrTag(type: 'e', value: 'root123', marker: 'root'),
        NostrTag(type: 'e', value: 'reply1', marker: 'reply'),
      ],
    );

    final nestedReply2 = NostrNote(
      id: 'nestedReply2',
      pubkey: 'pubkey5',
      created_at: 1635000400,
      kind: 1,
      content: 'A reply to the second reply.',
      sig: 'sig5',
      tags: [
        NostrTag(type: 'e', value: 'root123', marker: 'root'),
        NostrTag(type: 'e', value: 'reply2', marker: 'reply'),
      ],
    );

    // Create replies to the replies to the replies
    final nestedNestedReply1 = NostrNote(
      id: 'nestedNestedReply1',
      pubkey: 'pubkey6',
      created_at: 1635000500,
      kind: 1,
      content: 'A reply to the first nested reply.',
      sig: 'sig6',
      tags: [
        NostrTag(type: 'e', value: 'root123', marker: 'root'),
        NostrTag(type: 'e', value: 'nestedReply1', marker: 'reply'),
      ],
    );

    final nestedNestedReply2 = NostrNote(
      id: 'nestedNestedReply2',
      pubkey: 'pubkey7',
      created_at: 1635000600,
      kind: 1,
      content: 'A reply to the second nested reply.',
      sig: 'sig7',
      tags: [
        NostrTag(type: 'e', value: 'root123', marker: 'root'),
        NostrTag(type: 'e', value: 'nestedReply1', marker: 'reply'),
      ],
    );

    final notFoundReply = NostrNote(
      id: 'notFoundReply',
      pubkey: 'pubkey8',
      created_at: 1635000700,
      kind: 1,
      content: 'A reply to a note that does not exist.',
      sig: 'sig8',
      tags: [
        NostrTag(type: 'e', value: 'notFound', marker: 'root'),
      ],
    );

    // Create a list of all notes
    final List<NostrNote> allValidReplies = [
      reply1,
      reply2,
      nestedReply1,
      nestedReply2,
      nestedNestedReply1,
      nestedNestedReply2,
      notFoundReply,
    ];

    test('test building tree', () {
      final tree = EventFeed.buildRepliesTree(
        rootNoteId: rootNote.id,
        replies: allValidReplies,
      );
      for (final node in tree) {
        node.printTree();
      }

      // first level replies
      expect(tree.length, 2);
      expect(tree[0].value.id, equals(reply1.id));
      expect(tree[1].value.id, equals(reply2.id));

      // second level replies
      expect(tree[0].children.length, 1);
      expect(tree[0].children[0].value.id, equals(nestedReply1.id));

      expect(tree[1].children.length, 1);
      expect(tree[1].children[0].value.id, equals(nestedReply2.id));

      // third level replies

      expect(tree[0].children[0].children.length, 2);
      expect(tree[0].children[0].children[0].value.id,
          equals(nestedNestedReply1.id));
      expect(tree[0].children[0].children[1].value.id,
          equals(nestedNestedReply2.id));

      expect(tree[1].children[0].children.length, 0);
    });
  });
}
