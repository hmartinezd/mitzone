// Request coordinates are transient search input, never presence evidence.
export const nearbyProviderTimeoutMs = 10_000;

export function nearbyCoordinates(
  body: unknown,
): { latitude: number; longitude: number } | null {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return null;
  }
  const { latitude, longitude } = body as Record<string, unknown>;
  if (
    typeof latitude !== "number" || typeof longitude !== "number" ||
    !Number.isFinite(latitude) || !Number.isFinite(longitude) ||
    Math.abs(latitude) > 90 || Math.abs(longitude) > 180
  ) return null;
  return { latitude, longitude };
}
