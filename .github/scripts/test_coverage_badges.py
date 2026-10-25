# Written by Codex
import tempfile
import unittest
from pathlib import Path
from xml.etree import ElementTree

import coverage_badges


SVG_NAMESPACE = "{http://www.w3.org/2000/svg}"


class CoverageYearsTests(unittest.TestCase):
    def test_years_use_only_exact_tracked_dataset_paths(self):
        filenames = [
            "data/shp_dot_2027.rda",
            "data/shp_dot_2005.rda",
            "data/shp_dot_2007.rda",
            "data/shp_dot_2005.rda",
            "data/shp_dot_2025.rda.backup",
            "data/shp_dot_2025_extra.rda",
            "data/shp_dot_20251.rda",
            "data/shp_dot_205.rda",
            "data/shp_dot_notes.rda",
            "data/shp_dot_2025.rds",
            "data/nested/shp_dot_2025.rda",
            "archive/data/shp_dot_2025.rda",
            "data-raw/shp_dot_2025.rda",
            "data/shp_hex_2025.rda",
            "data/info_2025.rda",
        ]

        self.assertEqual(
            coverage_badges.years_for_files(filenames, "shp_dot_"),
            [2005, 2007, 2027],
        )
        self.assertEqual(
            coverage_badges.years_for_files(filenames, "info_"), [2025]
        )
        self.assertEqual(coverage_badges.years_for_files([], "shp_dot_"), [])

    def test_year_formatting_preserves_gaps_and_deduplicates(self):
        cases = [
            ([], "none"),
            ([2027], "2027"),
            ([2005, 2007, 2009], "2005-2009"),
            ([2005, 2009], "2005, 2009"),
            (
                [2027, 2007, 2019, 2005, 2013, 2017, 2005],
                "2005-2007, 2013, 2017-2019, 2027",
            ),
        ]
        for years, expected in cases:
            with self.subTest(years=years):
                self.assertEqual(coverage_badges.format_years(years), expected)


class CoverageBadgeTests(unittest.TestCase):
    def test_badges_are_valid_svg_with_escaped_accessible_and_visible_text(self):
        label = 'District names <bundled> & "descriptions"'
        message = '2005-2007 & <2027> "Congress years"'
        svg = coverage_badges.badge_svg(label, message)
        root = ElementTree.fromstring(svg)

        self.assertEqual(root.tag, f"{SVG_NAMESPACE}svg")
        title = root.find(f"{SVG_NAMESPACE}title")
        self.assertIsNotNone(title)
        title_text = "".join(title.itertext())
        self.assertIn(label, title_text)
        self.assertIn(message, title_text)
        visible_text = [
            "".join(element.itertext())
            for element in root.iter(f"{SVG_NAMESPACE}text")
        ]
        self.assertIn(label, visible_text)
        self.assertIn(message, visible_text)

    def test_writing_badges_keeps_each_products_actual_coverage(self):
        filenames = [
            "data/shp_dot_2027.rda",
            "data/shp_dot_2005.rda",
            "data/shp_dot_2007.rda",
            "data/shp_dot_2007.rda",
            "data/shp_hex_2013.rda",
            "data/shp_hex_2017.rda",
            "data/info_2025.rda",
            "data/shp_states.rda",
            "data/info_2027.rda.backup",
        ]
        expected_messages = {
            "dotmaps.svg": "2005-2007, 2027",
            "hexmaps.svg": "2013, 2017",
            "names.svg": "2025",
        }

        with tempfile.TemporaryDirectory() as temporary_directory:
            output_dir = Path(temporary_directory) / "badges"
            coverage_badges.write_badges(filenames, output_dir)

            self.assertEqual(
                {path.name for path in output_dir.iterdir()}, set(expected_messages)
            )
            for filename, expected_message in expected_messages.items():
                with self.subTest(filename=filename):
                    root = ElementTree.fromstring(
                        (output_dir / filename).read_text(encoding="utf-8")
                    )
                    visible_text = [
                        "".join(element.itertext())
                        for element in root.iter(f"{SVG_NAMESPACE}text")
                    ]
                    self.assertIn(expected_message, visible_text)

            first_output = {
                path.name: path.read_bytes() for path in output_dir.iterdir()
            }
            coverage_badges.write_badges(filenames, output_dir)
            repeated_output = {
                path.name: path.read_bytes() for path in output_dir.iterdir()
            }
            self.assertEqual(repeated_output, first_output)

    def test_missing_bundled_families_report_none(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            output_dir = Path(temporary_directory)
            coverage_badges.write_badges(["data/shp_states.rda"], output_dir)

            for filename in ("dotmaps.svg", "hexmaps.svg", "names.svg"):
                with self.subTest(filename=filename):
                    root = ElementTree.fromstring(
                        (output_dir / filename).read_text(encoding="utf-8")
                    )
                    visible_text = [
                        "".join(element.itertext())
                        for element in root.iter(f"{SVG_NAMESPACE}text")
                    ]
                    self.assertIn("none", visible_text)


if __name__ == "__main__":
    unittest.main()
