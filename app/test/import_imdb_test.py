"""Regression test for anonymous principal credits in the official IMDb files."""
import gzip
import contextlib
from pathlib import Path
import sqlite3
import tempfile
import unittest

from tool.import_imdb import build_index, DATASETS
from tool.prepare_device_imdb import prepare


class PersonalIndexTest(unittest.TestCase):
    def test_device_asset_contains_only_selected_imdb_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with contextlib.closing(sqlite3.connect(root / 'full.sqlite')) as db:
                db.executescript('''
                    CREATE TABLE titles(id INTEGER PRIMARY KEY, title TEXT, original TEXT, kind TEXT, year INTEGER, end_year INTEGER, minutes INTEGER, genres TEXT);
                    CREATE TABLE ratings(id INTEGER PRIMARY KEY, score REAL, votes INTEGER);
                    CREATE TABLE cast_members(title_id INTEGER, position INTEGER, person_id INTEGER, characters TEXT, PRIMARY KEY(title_id,position));
                    CREATE TABLE people(id INTEGER PRIMARY KEY, name TEXT, birth INTEGER, death INTEGER, professions TEXT, known_for TEXT);
                    INSERT INTO titles VALUES(1,'A film',NULL,'movie',2022,NULL,105,'Comedy');
                    INSERT INTO titles VALUES(2,'A film',NULL,'tvSeries',2022,NULL,NULL,'Drama');
                    INSERT INTO titles VALUES(3,'A show',NULL,'tvSeries',2017,NULL,NULL,'Drama');
                    INSERT INTO titles VALUES(4,'Missing',NULL,'movie',2022,NULL,101,NULL);
                    INSERT INTO ratings VALUES(1,7.2,12345);
                    INSERT INTO cast_members VALUES(1,1,8,NULL),(3,1,8,NULL),(4,1,9,NULL);
                    INSERT INTO people VALUES(8,'Selected actor',NULL,NULL,'actor',NULL),(9,'Other actor',NULL,NULL,'actor',NULL);
                    PRAGMA user_version=1;
                ''')
            with contextlib.closing(sqlite3.connect(root / 'catalog.sqlite')) as db:
                db.executescript('''
                    CREATE TABLE movies(source_id,stream_id,name,release_year,external_id);
                    CREATE TABLE series_items(source_id,series_id,name,release_year,external_id);
                    CREATE TABLE discovery_entries(source_id,kind,item_id,fingerprint,payload);
                    CREATE TABLE sources(secret);
                    INSERT INTO sources VALUES('private-source-test');
                    INSERT INTO movies VALUES(6,18,'A film 2022',NULL,NULL);
                    INSERT INTO series_items VALUES(6,22,'Local name',NULL,'tt0000003');
                ''')
            asset, count = prepare(root / 'full.sqlite', root / 'catalog.sqlite', root / 'assets')
            self.assertEqual(count, 2)
            unpacked = gzip.decompress(asset.read_bytes())
            self.assertNotIn(b'private-source-test', unpacked)
            self.assertNotIn(b'Local name', unpacked)
            (root / 'device.sqlite').write_bytes(unpacked)
            with contextlib.closing(sqlite3.connect(root / 'device.sqlite')) as device:
                self.assertEqual(device.execute('select id from titles order by id').fetchall(), [(1,), (3,)])
                self.assertEqual(device.execute('select name from people').fetchall(), [('Selected actor',)])
                self.assertEqual(device.execute('select score from ratings').fetchone(), (7.2,))
                self.assertEqual(device.execute("select count(*) from sqlite_master where type='table'").fetchone(), (4,))

    def test_anonymous_credit_and_interrupted_refresh(self):
        missing = r"\N"
        data = {
            "title.basics": [["tt0000012", "movie", missing, "Original title", "0", "2020", missing, "101", "Drama"]],
            "title.ratings": [["tt0000012", "7.8", "10"]],
            "title.principals": [
                ["tt0000012", "1", "nm0000001", "actor", missing, missing],
                ["tt0000012", "2", "nm0000002", "actress", missing, '["Lead"]'],
            ],
            "name.basics": [
                ["nm0000001", missing, missing, missing, missing, missing],
                ["nm0000002", "Performer", missing, missing, "actress", "tt0000012"],
            ],
        }
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp)
            for dataset, records in data.items():
                with gzip.open(dest / (dataset + ".tsv.gz"), "wt", encoding="utf-8") as f:
                    f.write(DATASETS[dataset].replace(" ", "\t") + "\n")
                    f.writelines("\t".join(record) + "\n" for record in records)
            output = dest / "imdb.sqlite"
            build_index(dest, output)
            db = sqlite3.connect(output)
            try:
                self.assertEqual(db.execute("SELECT title,original FROM titles").fetchone(),
                                 ("Original title", None))
                self.assertEqual(db.execute("SELECT name,characters FROM cast_members JOIN people ON person_id=id").fetchall(),
                                 [("Performer", '["Lead"]')])
            finally:
                db.close()
            original = output.read_bytes()
            (dest / "name.basics.tsv.gz").unlink()
            with self.assertRaises(FileNotFoundError):
                build_index(dest, output)
            self.assertEqual(output.read_bytes(), original)
