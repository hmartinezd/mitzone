"""Run against a disposable migrated PostgreSQL database as its administrator.

Uses real pair-lock contention, not sleeps, to order acceptance before blocking.
"""
import argparse
import os
import subprocess
import time
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('--psql', default='psql')
parser.add_argument('--host', required=True)
parser.add_argument('--port', required=True)
parser.add_argument('--database', required=True)
args = parser.parse_args()
command = [args.psql, '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', args.host,
           '-p', args.port, '-d', args.database]
a, b = sorted([str(uuid.uuid4()), str(uuid.uuid4())])
encounter = str(uuid.uuid4())


def sql(statement, user=None, check=True):
    if user:
        statement = f"set role authenticated; set request.jwt.claim.sub='{user}'; " + statement
    result = subprocess.run(command + ['-c', statement], text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(result.stderr)
    return result


acceptance = blocking = None
try:
    sql(f"insert into auth.users(id) values ('{a}'),('{b}'); "
        f"insert into encounters(id,user_a,user_b,context_id,overlap_start,overlap_end) "
        f"values ('{encounter}','{a}','{b}','test:foreground',now(),now()+interval '30 minutes');")
    request = sql(f"select id from send_connection_request('{b}','{encounter}');", a).stdout.strip()
    acceptance = subprocess.Popen(command, text=True, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    acceptance.stdin.write(f"begin; set role authenticated; set request.jwt.claim.sub='{b}';\n"
                           f"select accept_connection_request('{request}');\n\\echo ACCEPTED\n")
    acceptance.stdin.flush()
    while acceptance.stdout.readline().strip() != 'ACCEPTED':
        if acceptance.poll() is not None:
            raise AssertionError(acceptance.stderr.read())
    # The first session now holds the relationship lock until explicitly committed.
    environment = dict(os.environ, PGAPPNAME='mitzone_relationship_block_race')
    blocking = subprocess.Popen(command + ['-c',
        f"set role authenticated; set request.jwt.claim.sub='{a}'; "
        f"insert into blocks(blocker_user_id,blocked_user_id) values ('{a}','{b}');"],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=environment)
    deadline = time.monotonic() + 10
    while sql("select exists(select 1 from pg_locks l join pg_stat_activity s on s.pid=l.pid "
              "where s.application_name='mitzone_relationship_block_race' "
              "and l.locktype='advisory' and not l.granted);").stdout.strip() != 't':
        if blocking.poll() is not None or time.monotonic() > deadline:
            raise AssertionError('block did not wait for the in-flight acceptance')
    acceptance.stdin.write('commit;\n\\q\n')
    acceptance.stdin.flush()
    acceptance.wait(timeout=10)
    _, errors = blocking.communicate(timeout=10)
    if blocking.returncode:
        raise AssertionError(errors)
    assert sql(f"select count(*)=1 and bool_and(terminated_at is not null) "
               f"from connections where user_a_id='{a}' and user_b_id='{b}';").stdout.strip() == 't'
    sql(f"delete from blocks where blocker_user_id='{a}' and blocked_user_id='{b}';", a)
    for user, other in [(a, b), (b, a)]:
        assert sql(f"select get_relationship_state('{other}');", user).stdout.strip() == 'none'
    denied = sql(f"select accept_connection_request('{request}');", b, check=False)
    assert denied.returncode and 'request unavailable' in denied.stderr
    print('PASS: blocking serializes with acceptance; unblock cannot revive consent')
finally:
    for process in [acceptance, blocking]:
        if process is not None and process.poll() is None:
            process.terminate()
            process.wait(timeout=10)
    # Only this test's random fixture IDs are deleted, in FK dependency order.
    sql(f"delete from blocks where blocker_user_id in ('{a}','{b}'); "
        f"delete from connection_requests where encounter_id='{encounter}'; "
        f"delete from connections where encounter_id='{encounter}'; "
        f"delete from encounters where id='{encounter}'; "
        f"delete from auth.users where id in ('{a}','{b}');")
