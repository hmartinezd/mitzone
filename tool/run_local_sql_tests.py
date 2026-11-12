#!/usr/bin/env python3
"""Create a new disposable Unix-socket-only PostgreSQL cluster; never use a remote DB."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pg-bin', type=Path, default=Path('/private/tmp/mitzone-pg17/bin'))
    parser.add_argument('--through', type=int, default=9999)
    parser.add_argument('--test', action='append', default=[])
    parser.add_argument('--concurrency', action='store_true')
    parser.add_argument('--strict-grants', action='store_true',
                        help='Model staging: no CRUD defaults, residual Dxtm defaults, automatic RLS on new public tables.')
    args = parser.parse_args()
    for name in ['initdb', 'pg_ctl', 'psql', 'createdb']:
        if not (args.pg_bin / name).is_file():
            parser.error('Local PostgreSQL binaries are required; no external database fallback is allowed.')
    scratch = Path(tempfile.mkdtemp(prefix='mitzone-sql-', dir='/private/tmp'))
    scratch.chmod(0o700)
    socket = scratch / 'socket'
    socket.mkdir(mode=0o700)
    data = scratch / 'data'
    database = 'mitzone_test_' + scratch.name.removeprefix('mitzone-sql-').replace('-', '_')
    env = {k: v for k, v in os.environ.items() if not k.startswith('PG')}
    env.update(LC_ALL='C', LANG='C')
    port = '55439'
    started = False
    results = []
    start = time.time()
    def run(command, label):
        result = subprocess.run([str(x) for x in command], env=env, text=True, capture_output=True)
        (scratch / (label + '.log')).write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError(f'{label} failed: {result.stderr[-3500:]}')
        return result.stdout
    try:
        run([args.pg_bin/'initdb', '-D', data, '--no-locale', '--encoding=UTF8', '--auth=trust'], 'initdb')
        run([args.pg_bin/'pg_ctl', '-D', data, '-l', scratch/'server.log', '-o',
             f"-h '' -k {socket} -p {port}", '-w', 'start'], 'start')
        started = True
        run([args.pg_bin/'createdb', '-h', socket, '-p', port, database], 'createdb')
        psql = [args.pg_bin/'psql', '-X', '-v', 'ON_ERROR_STOP=1', '-h', socket, '-p', port, '-d', database]
        run(psql + ['-v', 'strict_grants=' + ('true' if args.strict_grants else 'false'),
                    '-f', ROOT/'tool/local_sql_bootstrap.sql'], 'bootstrap')
        for migration in sorted((ROOT/'supabase/migrations').glob('*.sql')):
            if int(migration.name.split('_')[0]) <= args.through:
                run(psql + ['-f', migration], migration.stem)
        tests = args.test or ['beta_reporting_presence_authorization.sql', 'beta_encounter_window_refresh.sql',
                             'beta_dedup_session_encounters.sql', 'beta_two_account_journey.sql',
                             'relationship_termination.sql']
        if not args.test and args.through >= 31:
            tests.append('beta_explicit_privileges.sql')
        for name in tests:
            path = ROOT/'supabase/tests'/name
            if path.parent != ROOT/'supabase/tests' or not path.is_file():
                raise RuntimeError('Only checked-in local SQL test files are supported.')
            try:
                run(psql + ['-f', path], 'test_' + path.stem)
            except RuntimeError:
                results.append({'test': name, 'status': 'FAIL'})
                raise
            results.append({'test': name, 'status': 'PASS'})
        if args.concurrency:
            for script in ['relationship_termination_concurrency.py', 'beta_encounter_concurrency.py']:
                try:
                    run([sys.executable, ROOT/'supabase/tests'/script,
                         '--psql', args.pg_bin/'psql', '--host', socket, '--port', port,
                         '--database', database], script.removesuffix('.py'))
                except RuntimeError:
                    results.append({'test': script, 'status': 'FAIL'})
                    raise
                results.append({'test': script, 'status': 'PASS'})
    finally:
        if started or (data/'postmaster.pid').exists():
            run([args.pg_bin/'pg_ctl', '-D', data, '-m', 'immediate', '-w', 'stop'], 'stop')
        print(json.dumps({'database': database, 'transport': 'private Unix socket; TCP disabled',
                          'grant_model': 'strict staging: no CRUD defaults; residual Dxtm + automatic RLS' if args.strict_grants else 'legacy platform defaults',
                          'logs': str(scratch), 'tests': results, 'seconds': round(time.time()-start,1)}, indent=2))


if __name__ == '__main__':
    main()
