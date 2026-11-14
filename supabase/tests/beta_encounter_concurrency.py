"""Real concurrent deduplication against a disposable local Unix-socket DB only."""
import argparse
import os
from pathlib import Path
import subprocess
import time
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('--psql', required=True)
parser.add_argument('--host', required=True)
parser.add_argument('--port', required=True)
parser.add_argument('--database', required=True)
args = parser.parse_args()
if not args.database.startswith('mitzone_test_') or not Path(args.host).resolve().is_relative_to(Path('/private/tmp')):
    parser.error('Only newly created local mitzone_test_* Unix-socket databases are supported.')
command = [args.psql, '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', args.host,
           '-p', args.port, '-d', args.database]
a, b = sorted([str(uuid.uuid4()), str(uuid.uuid4())])
ea, eb = str(uuid.uuid4()), str(uuid.uuid4())


def sql(statement, user=None):
    if user:
        statement = f"set role authenticated; set request.jwt.claim.sub='{user}'; " + statement
    result = subprocess.run(command + ['-c', statement], text=True, capture_output=True, timeout=15)
    if result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout.strip()


first = second = None
try:
    assert sql('select inet_server_addr() is null;') == 't'
    sql(f"insert into auth.users(id) values('{a}'),('{b}'); "
        "insert into presence_evidence(id,subject_user_id,context_id,observed_start,observed_end,source,expires_at) values "
        f"('{ea}','{a}','cell:100:100',now()-interval '10 minutes',now()-interval '30 seconds','geolocation',now()+interval '20 minutes'),"
        f"('{eb}','{b}','cell:100:101',now()-interval '10 minutes',now()-interval '30 seconds','geolocation',now()+interval '20 minutes');")
    first = subprocess.Popen(command, text=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    first.stdin.write(f"begin; set role authenticated; set request.jwt.claim.sub='{a}';\n"
                      f"select count(*) from process_presence_evidence('{ea}');\n\\echo INSERTED\n")
    first.stdin.flush()
    while first.stdout.readline().strip() != 'INSERTED':
        if first.poll() is not None:
            raise AssertionError(first.stderr.read())
    second = subprocess.Popen(command + ['-c',
        f"set role authenticated; set request.jwt.claim.sub='{b}'; select count(*) from process_presence_evidence('{eb}');"],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        env=dict(os.environ, PGAPPNAME='mitzone_encounter_unique_race'))
    deadline = time.monotonic() + 10
    while sql("select exists(select 1 from pg_locks l join pg_stat_activity s on s.pid=l.pid "
              "where s.application_name='mitzone_encounter_unique_race' and not l.granted);") != 't':
        if second.poll() is not None or time.monotonic() > deadline:
            raise AssertionError('opposite-caller insert did not contend on the uncommitted encounter')
    first.stdin.write('commit;\n\\q\n')
    first.stdin.flush()
    first.wait(timeout=10)
    output, errors = second.communicate(timeout=10)
    if second.returncode:
        raise AssertionError(errors)
    assert output.strip().endswith('1')
    assert sql(f"select count(*)=1 from encounters where user_a='{a}' and user_b='{b}';") == 't'
    assert sql(f"select bool_and(context_id='cell:100:100~nearby') from encounters where user_a='{a}' and user_b='{b}';") == 't'
    print('PASS: opposite-cell concurrent processing waits on the unique key and produces exactly one canonical encounter')
finally:
    for process in [first, second]:
        if process is not None and process.poll() is None:
            process.kill()
            process.wait()
    sql(f"delete from auth.users where id in('{a}','{b}');")
