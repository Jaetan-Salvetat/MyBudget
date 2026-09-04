from corpus.conventions import CLASS_GUIDE
from taxonomy import ACTIVE_LABELS

MIN_GUIDE_LENGTH = 40


def test_class_guide_covers_every_active_class_and_nothing_else():
    assert set(CLASS_GUIDE) == set(ACTIVE_LABELS)


def test_every_guide_entry_describes_the_class():
    for slug, guide in CLASS_GUIDE.items():
        assert len(guide) >= MIN_GUIDE_LENGTH, slug
