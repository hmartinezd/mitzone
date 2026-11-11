import { assertEquals } from 'https://deno.land/std@0.224.0/assert/assert_equals.ts';
import { isAuthorizedWebhook } from './webhook_auth.ts';

Deno.test('rejects missing or incorrect webhook secret', () => {
  assertEquals(isAuthorizedWebhook(new Request('https://example.test'), undefined), false);
  assertEquals(isAuthorizedWebhook(new Request('https://example.test', { headers: { 'x-mitzone-webhook-secret': 'wrong' } }), 'expected'), false);
});

Deno.test('accepts the dedicated webhook secret', () => {
  assertEquals(isAuthorizedWebhook(new Request('https://example.test', { headers: { 'x-mitzone-webhook-secret': 'expected' } }), 'expected'), true);
});
