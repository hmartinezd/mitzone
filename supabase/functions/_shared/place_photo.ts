// Resolve one fresh provider photo per place. Never persist photo resource names,
// forward the Google key to clients, or let an image failure hide nearby places.
export async function placePhoto(
  place: any,
  apiKey: string,
  fetcher: typeof fetch = fetch,
) {
  const photo = Array.isArray(place.photos) ? place.photos[0] : null;
  if (
    !photo || typeof photo.name !== "string" || typeof place.id !== "string" ||
    !/^places\/[^/]+\/photos\/[^/?#]+$/.test(photo.name) ||
    !photo.name.startsWith(`places/${place.id}/photos/`)
  ) return {};
  try {
    const url = new URL(`https://places.googleapis.com/v1/${photo.name}/media`);
    url.searchParams.set("maxWidthPx", "720");
    url.searchParams.set("skipHttpRedirect", "true");
    const response = await fetcher(url, {
      headers: { "X-Goog-Api-Key": apiKey },
      signal: AbortSignal.timeout(4000),
      redirect: "error",
    });
    if (!response.ok) return {};
    const payload = await response.json();
    const imageReference = safeGooglePhotoUri(payload.photoUri);
    if (!imageReference) return {};
    const imageAttribution =
      (Array.isArray(photo.authorAttributions) ? photo.authorAttributions : [])
        .map((author: any) =>
          typeof author.displayName === "string"
            ? author.displayName.trim()
            : ""
        )
        .filter(Boolean).join(" · ");
    return { imageReference, imageAttribution: imageAttribution || null };
  } catch (_) {
    return {};
  }
}

export function safeGooglePhotoUri(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value);
    const allowed = ["googleusercontent.com", "ggpht.com"].some((host) =>
      url.hostname === host || url.hostname.endsWith(`.${host}`)
    );
    if (
      url.protocol !== "https:" || !allowed || url.username || url.password ||
      url.port || [...url.searchParams.keys()].some((key) =>
        /key|token|secret/i.test(key)
      )
    ) return null;
    return url.toString();
  } catch (_) {
    return null;
  }
}
