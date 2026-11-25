"""Prepare a private Flutter asset from a personal IMDb index and local library."""

import argparse
import contextlib
import gzip
import hashlib
import json
from pathlib import Path
import re
import shutil
import sqlite3
import tempfile


def readonly(path):
    return sqlite3.connect(path.resolve().as_uri() + '?mode=ro', uri=True)


def catalog_keys(library):
    # Use the same conservative title/year/kind identity as Home. Preserve all
    # candidates of an ambiguous title so the device can decline that match.
    names, exact = set(), set()
    imdb = re.compile(r'tt([0-9]{7,12})')
    suffix = re.compile(r'\s+(19\d{2}|20\d{2})$|\s*[\[(](19\d{2}|20\d{2})[\])]$|[\s._-]+(?:2160p|1080p|720p|4k|uhd|fhd|hd)$', re.I)
    for table, item, kind in [('movies', 'stream_id', 'vod'), ('series_items', 'series_id', 'series')]:
        rows = library.execute(f'''SELECT c.name,c.release_year,c.external_id,e.fingerprint,e.payload
            FROM {table} c LEFT JOIN discovery_entries e ON e.source_id=c.source_id
                AND e.kind=? AND e.item_id=c.{item}''', (kind,))
        for raw, year, external, fingerprint, payload in rows:
            title = re.sub(r'^\s*\[?(?:ar|en|fr|de|us|uk)\]?\s*[|:]\s*', '', raw, flags=re.I).strip()
            title = re.sub(r'\s+(مدبلج|مترجم)$', '', title).strip()
            if external and (match := imdb.fullmatch(external)):
                exact.add(int(match[1]))
            if payload and payload != 'null':
                try:
                    label, saved_year, saved_id = json.loads(fingerprint)
                    cached = json.loads(payload)['title']
                    if (label == raw and (not year or not saved_year or year == saved_year)
                            and (not external or not saved_id or external == saved_id)):
                        if match := imdb.fullmatch(cached['ids'].get('imdb') or ''):
                            exact.add(int(match[1]))
                except (ValueError, KeyError, AttributeError, TypeError):
                    pass
            while match := suffix.search(title):
                if match.start() == 0:
                    break
                found_year = match[1] or match[2]
                if year and found_year and str(year) != found_year:
                    break
                if found_year:
                    year = int(found_year)
                title = title[:match.start()].strip()
            if year:
                aliases = [title]
                if re.search(r'[\u0600-\u06ff]', title):
                    aliases += re.split(r'\s+[-|–—]\s+', title)
                names.update((name.strip().lower(), year, int(kind == 'series')) for name in aliases if name.strip())
    return names, exact


def prepare(index, library, directory):
    directory.mkdir(parents=True, exist_ok=True)
    with contextlib.closing(readonly(library)) as catalog:
        names, exact = catalog_keys(catalog)
    with tempfile.TemporaryDirectory(dir=directory) as staging:
        database = Path(staging) / 'index.sqlite'
        with contextlib.closing(sqlite3.connect(database, uri=True)) as db:
            db.execute('ATTACH DATABASE ? AS imdb', (index.resolve().as_uri() + '?mode=ro',))
            if db.execute('PRAGMA imdb.user_version').fetchone()[0] != 1:
                raise ValueError('Unsupported personal IMDb index')
            db.executescript('''
                PRAGMA journal_mode=OFF;
                PRAGMA synchronous=OFF;
                CREATE TEMP TABLE wanted(name,year,series,PRIMARY KEY(name,year,series)) WITHOUT ROWID;
                CREATE TEMP TABLE selected(id INTEGER PRIMARY KEY);
            ''')
            db.executemany('INSERT INTO wanted VALUES(?,?,?)', names)
            db.executemany('INSERT INTO selected VALUES(?)', ((i,) for i in exact))
            for field in ('title', 'original'):
                db.execute(f'''INSERT OR IGNORE INTO selected SELECT t.id FROM imdb.titles t CROSS JOIN wanted w
                    ON w.name=lower(t.{field}) AND w.year=t.year AND w.series=(t.kind IN ('tvSeries','tvMiniSeries'))
                    WHERE t.kind IN ('movie','tvMovie','video','tvSeries','tvMiniSeries') AND t.{field} IS NOT NULL''')
            for table in ('titles', 'ratings', 'cast_members', 'people'):
                schema = db.execute("SELECT sql FROM imdb.sqlite_master WHERE type='table' AND name=?", (table,)).fetchone()[0]
                db.execute(schema)
            db.executescript('''
                INSERT INTO titles SELECT * FROM imdb.titles WHERE id IN selected;
                INSERT INTO ratings SELECT * FROM imdb.ratings WHERE id IN selected;
                INSERT INTO cast_members SELECT * FROM imdb.cast_members WHERE title_id IN selected;
                INSERT INTO people SELECT * FROM imdb.people WHERE id IN (SELECT person_id FROM cast_members);
                CREATE INDEX cast_by_person ON cast_members(person_id,title_id);
                CREATE INDEX titles_by_year ON titles(year);
                PRAGMA user_version=1;
            ''')
            count = db.execute('SELECT count(*) FROM titles').fetchone()[0]
            if not count:
                raise ValueError('No movie or series matched the selected library')
        compressed = Path(staging) / 'index.gz'
        with database.open('rb') as src, compressed.open('wb') as output:
            with gzip.GzipFile(filename='', mode='wb', fileobj=output, mtime=0, compresslevel=6) as target:
                shutil.copyfileobj(src, target)
        with compressed.open('rb') as stream:
            digest = hashlib.sha256(stream.read()).hexdigest()
        asset = directory / f'imdb-{digest}.sqlite.gz'
        compressed.replace(asset)
        for old in directory.glob('imdb-*.sqlite.gz'):
            if old != asset and re.fullmatch(r'imdb-[0-9a-f]{64}\.sqlite\.gz', old.name):
                old.unlink()
        return asset, count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--index', required=True, type=Path)
    parser.add_argument('--library', required=True, type=Path)
    parser.add_argument('--output-dir', required=True, type=Path)
    args = parser.parse_args()
    asset, count = prepare(args.index, args.library, args.output_dir)
    print(f'{count:,} IMDb titles. {asset.name} ({asset.stat().st_size:,} bytes).')
