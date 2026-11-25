"""Preview or apply this checkout's migrations to an explicit Supabase project."""

import argparse
from pathlib import Path
import re
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project_ref", help="Supabase project reference")
    parser.add_argument("--apply", action="store_true", help="Apply pending migrations")
    parser.add_argument(
        "--deploy-pairing",
        action="store_true",
        help="Deploy the TV pairing Edge Function after applying migrations",
    )
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9]{20}", args.project_ref):
        parser.error("project_ref must be the 20-character Supabase project reference")
    if args.deploy_pairing and not args.apply:
        parser.error("--deploy-pairing requires --apply")
    cli = shutil.which("supabase")
    if cli is None:
        parser.error("Install the Supabase CLI and add it to PATH")

    root = Path(__file__).resolve().parents[2]

    def supabase(*command):
        subprocess.run([cli, *command], cwd=root, check=True)

    remote = f"--remote={args.project_ref}"
    supabase("migration", "list", remote)
    supabase("db", "push", remote, "--dry-run")
    if args.apply:
        supabase("db", "push", remote)
        if args.deploy_pairing:
            supabase("functions", "deploy", "tv-pairing", remote, "--no-verify-jwt")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from None
