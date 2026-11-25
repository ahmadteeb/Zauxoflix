"""Build a private title and cast index from IMDb's non-commercial TSV files."""

import argparse
import contextlib
import gzip
import os
from pathlib import Path
import shutil
import sqlite3
import tempfile
from urllib.request import urlopen

DATASETS = {
    "title.basics": "tconst titleType primaryTitle originalTitle isAdult startYear endYear runtimeMinutes genres",
    "title.ratings": "tconst averageRating numVotes",
    "title.principals": "tconst ordering nconst category job characters",
    "name.basics": "nconst primaryName birthYear deathYear primaryProfession knownForTitles",
}
TITLE_KINDS = {b"movie", b"short", b"tvMovie", b"tvSeries", b"tvMiniSeries",
               b"tvShort", b"tvSpecial", b"video"}
CAST = {b"actor", b"actress", b"self"}
MISSING = b"\\N"


def field(value):
    return None if value == MISSING else value.decode("utf-8")


def rows(directory, dataset):
    print(f"Reading {dataset}", flush=True)
    with gzip.open(directory / (dataset + ".tsv.gz"), "rb") as stream:
        if stream.readline().decode().split() != DATASETS[dataset].split():
            raise ValueError(f"Unexpected columns in {dataset}")
        for line in stream:
            yield line.rstrip(b"\r\n").split(b"\t")


def build_index(directory, output):
    # Build beside the destination. A failed or interrupted refresh leaves the
    # previous complete index available to readers.
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output.parent) as staging:
        pending = Path(staging) / "imdb.sqlite"
        with contextlib.closing(sqlite3.connect(pending)) as db:
            db.executescript("""
                PRAGMA journal_mode=OFF;
                PRAGMA synchronous=OFF;
                PRAGMA cache_size=-98304;
                CREATE TABLE titles(id INTEGER PRIMARY KEY, title TEXT NOT NULL,
                    original TEXT, kind TEXT, year INTEGER, end_year INTEGER,
                    minutes INTEGER, genres TEXT);
                CREATE TABLE ratings(id INTEGER PRIMARY KEY, score REAL, votes INTEGER);
                CREATE TABLE cast_members(title_id INTEGER, position INTEGER, person_id INTEGER,
                    characters TEXT, PRIMARY KEY(title_id, position)) WITHOUT ROWID;
                CREATE TABLE people(id INTEGER PRIMARY KEY, name TEXT NOT NULL,
                    birth INTEGER, death INTEGER, professions TEXT, known_for TEXT);
            """)
            titles, people = set(), set()

            def title_rows():
                for tid, kind, name, original, _, year, end, minutes, genres in rows(directory, "title.basics"):
                    if kind in TITLE_KINDS and (name != MISSING or original != MISSING):
                        key = int(tid[2:])
                        titles.add(key)
                        label = field(name) or field(original)
                        yield (key, label, field(original) if field(original) != label else None,
                               field(kind), field(year), field(end), field(minutes), field(genres))

            def credits():
                for tid, order, pid, category, _, characters in rows(directory, "title.principals"):
                    if category not in CAST:
                        continue
                    key = int(tid[2:])
                    if key in titles:
                        person = int(pid[2:])
                        people.add(person)
                        yield key, int(order), person, field(characters)

            with db:
                db.executemany("INSERT INTO titles VALUES(?,?,?,?,?,?,?,?)", title_rows())
                db.executemany("INSERT INTO ratings VALUES(?,?,?)", (
                    (int(tid[2:]), float(score), int(votes))
                    for tid, score, votes in rows(directory, "title.ratings")
                    if int(tid[2:]) in titles))
                db.executemany("INSERT INTO cast_members VALUES(?,?,?,?)", credits())
                del titles
                db.executemany("INSERT INTO people VALUES(?,?,?,?,?,?)", (
                    (int(pid[2:]), field(name), field(birth), field(death), field(jobs), field(known))
                    for pid, name, birth, death, jobs, known in rows(directory, "name.basics")
                    if name not in (MISSING, b"") and int(pid[2:]) in people))
                db.execute("CREATE INDEX cast_by_person ON cast_members(person_id, title_id)")
                db.execute("PRAGMA user_version=1")
        os.replace(pending, output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path,
                        help="Path to imdb.sqlite in the app's Zauxoflix data folder")
    parser.add_argument("--datasets", type=Path,
                        help="Use four previously downloaded .tsv.gz files")
    args = parser.parse_args()
    if args.datasets:
        build_index(args.datasets, args.output)
        return
    with tempfile.TemporaryDirectory() as tmp:
        directory = Path(tmp)
        for name in DATASETS:
            filename = name + ".tsv.gz"
            print(f"Downloading {filename}", flush=True)
            with urlopen("https://datasets.imdbws.com/" + filename, timeout=60) as response:
                with (directory / filename).open("wb") as target:
                    shutil.copyfileobj(response, target)
        build_index(directory, args.output)


if __name__ == "__main__":
    main()
