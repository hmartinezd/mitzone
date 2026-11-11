import base64
import importlib.util
import json
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('preflight', Path(__file__).parents[1] / 'beta_preflight.py')
preflight = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preflight)


class BetaPreflightTest(unittest.TestCase):
    def config(self):
        return {'APP_ENV': 'staging', 'SUPABASE_URL': 'https://test.example.invalid',
                'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test_fixture_only'}

    def test_staging_client_configuration(self):
        self.assertEqual(preflight.validate_config(self.config()), [])

    def test_production_and_http_are_rejected(self):
        config = self.config()
        config.update(APP_ENV='production', SUPABASE_URL='http://test.example.invalid')
        self.assertEqual(len(preflight.validate_config(config)), 2)

    def test_privileged_jwt_is_rejected_without_printing_it(self):
        config = self.config()
        payload = base64.urlsafe_b64encode(json.dumps({'role': 'service_role'}).encode()).decode().rstrip('=')
        config['SUPABASE_PUBLISHABLE_KEY'] = f'fixture.{payload}.fixture'
        errors = preflight.validate_config(config)
        self.assertTrue(errors)
        self.assertNotIn(payload, ' '.join(errors))

    def test_secret_fields_and_malformed_values_fail_closed(self):
        config = self.config()
        config.update(SUPABASE_URL=None, SUPABASE_PUBLISHABLE_KEY=None, SERVICE_ROLE_KEY='fixture-only')
        self.assertEqual(len(preflight.validate_config(config)), 3)

    def test_local_static_release_regressions(self):
        results = preflight.inspect(Path(__file__).resolve().parents[2])
        checks = {x['check']: x['status'] for x in results}
        for name in ['android_release_network', 'no_background_location', 'no_debug_release_signing']:
            self.assertEqual(checks[name], 'PASS')
        self.assertEqual(checks['two_account_live_journey'], 'BLOCKED')


if __name__ == '__main__':
    unittest.main()
