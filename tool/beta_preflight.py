#!/usr/bin/env python3
"""Read-only local beta checks. Never connects to services or prints config values."""
import argparse
import base64
import json
from pathlib import Path
import re
from urllib.parse import urlparse
import xml.etree.ElementTree as ET


def validate_config(config):
    problems = []
    if config.get('APP_ENV') != 'staging':
        problems.append('Private beta configuration must explicitly select staging.')
    try:
        uri = urlparse(config.get('SUPABASE_URL', ''))
        valid_url = (uri.scheme == 'https' and bool(uri.hostname)
                     and not uri.username and not uri.password
                     and not uri.query and not uri.fragment
                     and 'YOUR_PROJECT' not in uri.netloc)
    except (TypeError, ValueError):
        valid_url = False
    if not valid_url:
        problems.append('A non-placeholder HTTPS backend URL is required.')
    key = config.get('SUPABASE_PUBLISHABLE_KEY', '')
    valid_key = isinstance(key, str) and key.startswith('sb_publishable_') and len(key) > 20 and 'REPLACE' not in key
    if isinstance(key, str) and key.count('.') == 2:
        try:
            payload = key.split('.')[1]
            role = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4))).get('role')
            valid_key = role == 'anon'
        except (ValueError, TypeError, UnicodeError):
            valid_key = False
    if not valid_key:
        problems.append('Only a client publishable/anon key is accepted; privileged keys are prohibited.')
    if any(re.search(r'(SERVICE_ROLE|PRIVATE_KEY|PASSWORD|ACCESS_TOKEN|SECRET)', name, re.I)
           for name in config):
        problems.append('Privileged credential fields must not be embedded in Flutter defines.')
    return problems


def inspect(root, config_path=None):
    results = []
    def add(name, passed, detail):
        results.append({'check': name, 'status': 'PASS' if passed else 'BLOCKED', 'detail': detail})
    manifest = ET.parse(root / 'android/app/src/main/AndroidManifest.xml').getroot()
    permissions = {p.attrib.get('{http://schemas.android.com/apk/res/android}name')
                   for p in manifest.findall('uses-permission')}
    add('android_release_network', 'android.permission.INTERNET' in permissions,
        'Internet permission must be in the main manifest, not only debug/profile.')
    add('no_background_location', 'android.permission.ACCESS_BACKGROUND_LOCATION' not in permissions,
        'Beta must not request background location.')
    gradle = (root / 'android/app/build.gradle.kts').read_text()
    add('no_debug_release_signing', not re.search(r'signingConfig\s*=\s*signingConfigs.getByName\("debug"\)', gradle),
        'Release must not silently use a debug signing key.')
    add('android_signing_available', (root / 'android/key.properties').is_file(),
        'Owner-controlled release signing is required before Android distribution; values are not inspected.')
    project = (root / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
    teams = re.findall(r'DEVELOPMENT_TEAM\s*=\s*([^;]+);', project)
    add('ios_team_configured', any(t.strip(' "') for t in teams),
        'An authorized Apple signing team/provisioning setup is required before TestFlight.')
    if config_path:
        try:
            config = json.loads(config_path.read_text())
            problems = validate_config(config) if isinstance(config, dict) else ['Configuration must be a JSON object.']
        except (OSError, ValueError):
            problems = ['Configuration is missing or invalid JSON.']
        add('staging_config', not problems, ' '.join(problems) or 'Local staging shape passes; backend ownership and deployment remain unverified.')
    else:
        add('staging_config', False, 'Provide --config with an explicitly authorized staging configuration. No local secrets are auto-discovered.')
    # These require observed runtime or owner/operations evidence, never source inference.
    for name, detail in [
        ('two_account_live_journey', 'Verify registration/recovery, profiles, physical foreground overlap, mutual connection and bidirectional chat on authorized nonproduction devices/accounts.'),
        ('server_security_and_migrations', 'Run all migration/RLS/RPC security checks on a disposable migrated database and verify approved staging parity.'),
        ('privacy_and_moderation_operations', 'Finalize age policy, entity/contact, retention/deletion disclosures, report-review ownership and beta feedback channel.'),
        ('device_and_accessibility', 'Verify device permissions, background/Stop/expiry, block enforcement, VoiceOver/TalkBack and 2x text in the candidate build.'),
        ('owner_distribution_approval', 'Signing, uploads, release publication and production changes require separate explicit owner approval.'),
    ]:
        add(name, False, detail)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--config', type=Path)
    args = parser.parse_args()
    results = inspect(args.root, args.config)
    print(json.dumps({'ready': all(x['status'] == 'PASS' for x in results), 'checks': results}, indent=2))
    return 0 if all(x['status'] == 'PASS' for x in results) else 1


if __name__ == '__main__':
    raise SystemExit(main())
