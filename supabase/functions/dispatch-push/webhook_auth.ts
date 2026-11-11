export function isAuthorizedWebhook(request: Request, expected: string | undefined): boolean {
  if (!expected) return false;
  const supplied = request.headers.get('x-mitzone-webhook-secret');
  return supplied !== null && supplied === expected;
}
