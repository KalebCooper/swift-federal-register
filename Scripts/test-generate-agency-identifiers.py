#!/usr/bin/env python3
"""Exercise catalog generation against the shipped snapshot and small synthetic inputs."""

import importlib.util
import json
import pathlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    "generate", pathlib.Path(__file__).with_name("generate-agency-identifiers.py")
)
generate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generate)

ROOT = pathlib.Path(__file__).resolve().parent.parent
SNAPSHOT = ROOT / "Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures/agencies.json"
CONFIGURATION = ROOT / ".swift-format"


def agency(slug, name=None):
    return {"slug": slug, "name": name or slug.replace("-", " ").title()}


class SnapshotTests(unittest.TestCase):
    def test_full_snapshot_is_deterministic_and_complete(self):
        first, count = generate.generate(SNAPSHOT, None, CONFIGURATION)
        second, _ = generate.generate(SNAPSHOT, None, CONFIGURATION)
        self.assertEqual(first, second)
        slugs = {entry["slug"] for entry in json.loads(SNAPSHOT.read_text())}
        self.assertEqual(count, len(slugs))
        self.assertEqual(first.count("public static let "), len(slugs))
        for slug in slugs:
            self.assertIn(f'rawValue: "{slug}")', first)
        for identifier in (
            "agricultureDepartment",
            "environmentalProtectionAgency",
            "healthAndHumanServicesDepartment",
        ):
            self.assertIn(f"  public static let {identifier} = Self(", first)
        self.assertIn("// Snapshot SHA-256: ", first)
        self.assertNotIn("\u2014", first)

    def test_member_count_follows_the_input(self):
        with tempfile.TemporaryDirectory() as temporary:
            snapshot = pathlib.Path(temporary) / "agencies.json"
            snapshot.write_text(json.dumps([agency("alpha-office"), agency("beta-office")]))
            source, count = generate.generate(snapshot, None, CONFIGURATION)
            self.assertEqual(count, 2)
            self.assertEqual(source.count("public static let "), 2)
            self.assertLess(source.index("alphaOffice"), source.index("betaOffice"))


class EntryTests(unittest.TestCase):
    def test_identifiers_are_lower_camel_case(self):
        self.assertEqual(generate.identifier_for("agriculture-department"), "agricultureDepartment")
        self.assertEqual(generate.identifier_for("action"), "action")

    def test_keywords_are_escaped(self):
        source = generate.render(generate.catalog_entries([agency("import")], {}), "0" * 64)
        self.assertIn('public static let `import` = Self(rawValue: "import")', source)

    def test_collision_fails(self):
        with self.assertRaises(generate.CatalogError) as context:
            generate.catalog_entries([agency("a-b"), agency("ab", "AB")], {"ab": "aB"})
        self.assertIn("collides", str(context.exception))

    def test_empty_slug_fails(self):
        with self.assertRaises(generate.CatalogError) as context:
            generate.catalog_entries([agency("alpha"), {"slug": "", "name": "Blank"}], {})
        self.assertIn("empty slug", str(context.exception))

    def test_duplicate_slug_fails(self):
        with self.assertRaises(generate.CatalogError) as context:
            generate.catalog_entries([agency("alpha"), agency("alpha")], {})
        self.assertIn("duplicate slug", str(context.exception))

    def test_invalid_token_fails_without_a_reviewed_name(self):
        with self.assertRaises(generate.CatalogError) as context:
            generate.catalog_entries([agency("9th-circuit"), agency("Mixed-Case")], {})
        self.assertIn("9th-circuit", str(context.exception))
        self.assertIn("Mixed-Case", str(context.exception))
        entries = generate.catalog_entries(
            [agency("9th-circuit")], {"9th-circuit": "ninthCircuit"}
        )
        self.assertEqual(entries, [("ninthCircuit", "9th-circuit", "9Th Circuit")])

    def test_unused_reviewed_name_fails(self):
        with self.assertRaises(generate.CatalogError) as context:
            generate.catalog_entries([agency("alpha")], {"beta": "beta"})
        self.assertIn("does not contain", str(context.exception))


class CommandTests(unittest.TestCase):
    def test_check_reports_drift_and_agreement(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            snapshot = root / "agencies.json"
            snapshot.write_text(json.dumps([agency("alpha-office")]))
            output = root / "Catalog.swift"
            arguments = ["--input", str(snapshot), "--output", str(output)]
            self.assertEqual(generate.main(arguments + ["--check"]), 1)
            self.assertEqual(generate.main(arguments), 0)
            self.assertEqual(generate.main(arguments + ["--check"]), 0)
            output.write_text(output.read_text().replace("alphaOffice", "alphaOffices"))
            self.assertEqual(generate.main(arguments + ["--check"]), 1)


if __name__ == "__main__":
    unittest.main()
