from __future__ import annotations

import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import daily_work_publish as daily


class DailyWorkPublishTests(unittest.TestCase):
    def test_extract_public_digest_excludes_internal_log(self) -> None:
        text = (
            "# Daily Work - 2026-05-24 [safiu]\n\n"
            "## Public digest\n\n"
            "- User-safe progress note.\n\n"
            "## Internal log\n\n"
            "- Local file and test detail.\n"
        )

        public = daily.extract_section(text, "Public digest")
        internal = daily.extract_section(text, "Internal log")
        storage = daily.markdown_public_to_storage(public, "2026-05-24", "safiu")

        self.assertIn("User-safe progress note", public)
        self.assertNotIn("Local file", public)
        self.assertIn("Local file", internal)
        self.assertIn("User-safe progress note", storage)
        self.assertNotIn("Local file", storage)
        self.assertEqual("Daily Work - 2026-05-24", daily.confluence_page_title("2026-05-24"))
        self.assertIn("daily-work:author:safiu:start", storage)

    def test_append_to_section_preserves_following_heading(self) -> None:
        text = (
            "# Daily Work - 2026-05-24 [safiu]\n\n"
            "## Public digest\n\n"
            "## Internal log\n"
        )

        updated = daily.append_to_section(text, "Public digest", "A public note")

        self.assertRegex(updated, r"## Public digest\s+- A public note\s+## Internal log")

    def test_unsafe_public_markers_are_detected_by_class(self) -> None:
        markers = daily.detect_unsafe_public_markers(
            "Run ssh user@example.test against 999.999.999.999"
        )

        self.assertIn("ssh_command", markers)
        self.assertIn("ip_address", markers)

    def test_merge_author_storage_preserves_other_authors(self) -> None:
        existing = (
            "<h1>Daily Work - 2026-05-24</h1>"
            "<!-- daily-work:author:ivan:start --><h2>ivan</h2><ul><li>Ivan note</li></ul><!-- daily-work:author:ivan:end -->"
            "<!-- daily-work:author:safiu:start --><h2>safiu</h2><ul><li>Old note</li></ul><!-- daily-work:author:safiu:end -->"
        )

        updated = daily.merge_author_storage(existing, "- New note", "2026-05-24", "safiu")

        self.assertIn("Ivan note", updated)
        self.assertIn("New note", updated)
        self.assertNotIn("Old note", updated)

    def test_merge_author_storage_replaces_unmarked_duplicate_author_sections(self) -> None:
        existing = (
            "<h1>Daily Work - 2026-05-24</h1>"
            "<h2>safiu</h2><ul><li>Old note</li></ul>"
            "<h2>ivan</h2><ul><li>Ivan note</li></ul>"
            "<h2>safiu</h2><ul><li>Duplicate note</li></ul>"
        )

        updated = daily.merge_author_storage(existing, "- New note", "2026-05-24", "safiu")

        self.assertIn("Ivan note", updated)
        self.assertIn("New note", updated)
        self.assertNotIn("Old note", updated)
        self.assertNotIn("Duplicate note", updated)
        self.assertEqual(updated.count("<h2>safiu</h2>"), 1)


if __name__ == "__main__":
    unittest.main()
