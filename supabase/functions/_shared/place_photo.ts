import { nearbyProviderTimeoutMs } from "./nearby_request.ts";

const photoName =
  /^places\/[A-Za-z0-9_-]{1,256}\/photos\/[A-Za-z0-9_-]{1,2048}$/;
const lifetimeMs = 15 * 60_000;
const mediaWidth = 720;
const maxBytes = 4 * 1024 * 1024;
const encoder = new TextEncoder();

function providerLink(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value.startsWith("//") ? `https:${value}` : value);
    if (
      url.protocol === "https:" && !url.username && !url.password &&
      !url.port &&
      [
        "maps.google.com",
        "www.google.com",
        "google.com",
        "maps.app.goo.gl",
        "lh3.googleusercontent.com",
      ].includes(url.hostname)
    ) {
      return url.href;
    }
  } catch {
    // Ignore malformed provider links.
  }
  return null;
}

async function signingKey(apiKey: string) {
  return await crypto.subtle.importKey(
    "raw",
    encoder.encode(apiKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

function signedPayload(name: string, userId: string, expiresAt: number) {
  return encoder.encode(
    JSON.stringify(["mitzone-place-photo-v1", name, userId, expiresAt]),
  );
}

export async function makePhoto(
  raw: unknown,
  placeId: string,
  userId: string,
  apiKey: string,
) {
  if (!raw || typeof raw !== "object") return null;
  const { name, googleMapsUri, authorAttributions } = raw as Record<
    string,
    unknown
  >;
  if (
    typeof name !== "string" || !photoName.test(name) ||
    !name.startsWith(`places/${placeId}/photos/`)
  ) return null;
  const expiresAt = Date.now() + lifetimeMs;
  const signature = await crypto.subtle.sign(
    "HMAC",
    await signingKey(apiKey),
    signedPayload(name, userId, expiresAt),
  );
  const authors = (Array.isArray(authorAttributions) ? authorAttributions : [])
    .flatMap((author) => {
      if (
        typeof author?.displayName !== "string" || !author.displayName.trim()
      ) return [];
      return [{
        displayName: author.displayName,
        uri: providerLink(author.uri),
        photoUri: providerLink(author.photoUri),
      }];
    });
  return {
    name,
    expiresAt,
    signature: btoa(String.fromCharCode(...new Uint8Array(signature))),
    googleMapsUri: providerLink(googleMapsUri),
    authors,
  };
}

export async function servePhoto(
  body: Record<string, unknown>,
  userId: string,
  apiKey: string,
  cors: Record<string, string>,
) {
  const headers = { ...cors, "Cache-Control": "private, no-store" };
  const fail = (status: number) =>
    Response.json(
      { error: "Photo unavailable" },
      { status, headers },
    );
  const { name, expiresAt, signature } = body;
  if (
    typeof name !== "string" || !photoName.test(name) ||
    typeof expiresAt !== "number" || !Number.isSafeInteger(expiresAt) ||
    expiresAt <= Date.now() || expiresAt > Date.now() + lifetimeMs ||
    typeof signature !== "string" || !/^[A-Za-z0-9+/]{43}=$/.test(signature)
  ) {
    return fail(400);
  }
  const valid = await crypto.subtle.verify(
    "HMAC",
    await signingKey(apiKey),
    Uint8Array.from(atob(signature), (c) => c.charCodeAt(0)),
    signedPayload(name, userId, expiresAt),
  );
  if (!valid) return fail(403);

  try {
    const signal = AbortSignal.timeout(nearbyProviderTimeoutMs);
    const media = new URL(`https://places.googleapis.com/v1/${name}/media`);
    media.searchParams.set("maxWidthPx", String(mediaWidth));
    media.searchParams.set("maxHeightPx", String(mediaWidth));
    media.searchParams.set("skipHttpRedirect", "true");
    const response = await fetch(media, {
      headers: { "X-Goog-Api-Key": apiKey },
      redirect: "error",
      signal,
    });
    if (response.status === 404) return fail(404);
    if (!response.ok) return fail(502);

    const { photoUri } = await response.json();
    const cdn = safeGooglePhotoUri(photoUri);
    if (!cdn) return fail(502);
    const image = await fetch(cdn, { redirect: "error", signal });
    const contentType = image.headers.get("Content-Type")?.split(";")[0];
    if (
      !image.ok || !image.body ||
      !["image/jpeg", "image/png", "image/webp"].includes(contentType ?? "") ||
      Number(image.headers.get("Content-Length")) > maxBytes
    ) {
      await image.body?.cancel();
      return fail(502);
    }

    const reader = image.body.getReader();
    const chunks: BlobPart[] = [];
    let size = 0;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maxBytes) {
        await reader.cancel();
        return fail(502);
      }
      chunks.push(value.slice());
    }
    if (!size) return fail(502);
    return new Response(new Blob(chunks), {
      headers: { ...headers, "Content-Type": "application/octet-stream" },
    });
  } catch {
    return fail(502);
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
