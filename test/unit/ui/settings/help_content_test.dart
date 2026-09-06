import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/settings/help_content.dart';
import 'package:mybudget/ui/settings/models/help_topic.dart';

void main() {
  final List<HelpTopic> topics = helpChapters
      .expand((HelpChapter chapter) => chapter.topics)
      .toList();

  group('catalogue d\'aide', () {
    test('chaque chapitre porte un intitulé et au moins un sujet', () {
      expect(helpChapters, isNotEmpty);

      for (final HelpChapter chapter in helpChapters) {
        expect(chapter.label, isNotEmpty);
        expect(chapter.topics, isNotEmpty);
      }
    });

    test('chaque sujet porte un titre, un résumé et du contenu', () {
      for (final HelpTopic topic in topics) {
        expect(topic.title, isNotEmpty);
        expect(topic.summary, isNotEmpty);
        expect(topic.paragraphs, isNotEmpty);
        expect(topic.paragraphs.every((String body) => body.isNotEmpty), isTrue);
      }
    });

    test('les titres de sujets sont uniques', () {
      final Set<String> titles = topics
          .map((HelpTopic topic) => topic.title)
          .toSet();

      expect(titles, hasLength(topics.length));
    });

    test('les résumés tiennent sur la ligne unique de l\'en-tête', () {
      for (final HelpTopic topic in topics) {
        expect(
          topic.summary.length,
          lessThanOrEqualTo(HelpTopic.summaryMaxLength),
          reason: 'Résumé trop long pour « ${topic.title} »',
        );
      }
    });

    test('chaque destination est proposée par un sujet', () {
      final Set<HelpDestination> reached = topics
          .map((HelpTopic topic) => topic.action?.destination)
          .nonNulls
          .toSet();

      expect(reached, HelpDestination.values.toSet());
    });

    test('chaque action porte un libellé', () {
      for (final HelpTopic topic in topics) {
        if (topic.action == null) continue;
        expect(topic.action!.label, isNotEmpty);
      }
    });
  });
}
