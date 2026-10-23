#!/usr/bin/env python3
"""CLI for safe, local project conversion through DawVert."""
import argparse
from pathlib import Path
import subprocess
import sys

FORMATS = {'.flp': ('flp', 'ableton', '.als'), '.als': ('ableton', 'flp', '.flp')}

def command(engine, source, dest, python):
    engine, source, dest, python = [Path(p).expanduser().resolve() for p in (engine, source, dest, python)]
    if source.suffix.lower() not in FORMATS:
        raise ValueError('Only FLP and ALS project files are supported')
    incoming, outgoing, extension = FORMATS[source.suffix.lower()]
    if dest.suffix.lower() != extension:
        raise ValueError('Output extension must be ' + extension)
    if not source.is_file():
        raise ValueError('Input does not exist')
    if dest.exists():
        raise ValueError('Output already exists; select a new filename')
    if not dest.parent.is_dir():
        raise ValueError('Output directory does not exist')
    if not (engine / 'dawvert_cmd.py').is_file() or not python.is_file():
        raise ValueError('Conversion engine not installed')
    return [str(python), 'dawvert_cmd.py', '-it', incoming, '-i', str(source), '-ot', outgoing, '-o', str(dest)]

def main():
    p = argparse.ArgumentParser()
    for name in ('engine', 'python', 'input', 'output'):
        p.add_argument('--' + name, required=True)
    args = p.parse_args()
    try:
        cmd = command(args.engine, args.input, args.output, args.python)
    except ValueError as exc:
        print('ERROR:', exc, file=sys.stderr, flush=True)
        return 2
    print('Converting project locally...', flush=True)
    result = subprocess.run(cmd, cwd=args.engine)
    if result.returncode != 0:
        print(f'Backend exited with status {result.returncode}', file=sys.stderr)
        return result.returncode
    output = Path(args.output)
    if not output.is_file() or output.stat().st_size == 0:
        print('No usable output file was created', file=sys.stderr)
        return 3
    print('DONE: ' + str(output), flush=True)
    return 0

if __name__ == '__main__':
    sys.exit(main())
