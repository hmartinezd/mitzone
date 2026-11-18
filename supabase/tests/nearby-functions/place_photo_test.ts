import {
  makePhoto,
  safeGooglePhotoUri,
  servePhoto,
} from "../../functions/_shared/place_photo.ts";

const apiKey = "fixture-key";
const user = "fixture-user";
const name = "places/fixture/photos/fixture";
const raw = {
  name,
  googleMapsUri: "https://www.google.com/maps/example-photo",
  authorAttributions: [{
    displayName: "Fixture photographer",
    uri: "//maps.google.com/maps/contrib/123",
    photoUri: "https://lh3.googleusercontent.com/fixture-avatar",
  }],
};

function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("returns one signed photo with provider attribution, or null without a valid photo", async () => {
  equal(await makePhoto(undefined, "fixture", user, apiKey), null);
  equal(
    await makePhoto(
      { name: "https://example.invalid" },
      "fixture",
      user,
      apiKey,
    ),
    null,
  );
  equal(await makePhoto(raw, "different-place", user, apiKey), null);
  const photo = await makePhoto(raw, "fixture", user, apiKey);
  equal(photo?.name, name);
  equal(photo?.googleMapsUri, raw.googleMapsUri);
  equal(photo?.authors, [{
    displayName: "Fixture photographer",
    uri: "https://maps.google.com/maps/contrib/123",
    photoUri: "https://lh3.googleusercontent.com/fixture-avatar",
  }]);
});

Deno.test("photo proxy binds references to a user, bounds media and handles provider failures", async () => {
  const photo = await makePhoto(raw, "fixture", user, apiKey);
  if (!photo) throw new Error("Missing fixture photo");
  const originalFetch = globalThis.fetch;
  const calls: string[] = [];
  let unavailable = false;
  let unsafe = false;
  globalThis.fetch = ((request: string | URL, init: RequestInit) => {
    const input = new URL(request);
    calls.push(input.hostname);
    if (input.hostname === "places.googleapis.com") {
      equal(input.pathname, `/v1/${name}/media`);
      equal(input.searchParams.get("maxWidthPx"), "720");
      equal(input.searchParams.get("key"), null);
      equal(new Headers(init.headers).get("X-Goog-Api-Key"), apiKey);
      return Promise.resolve(
        unavailable ? new Response(null, { status: 429 }) : Response.json({
          photoUri: unsafe
            ? "https://example.invalid/photo"
            : "https://lh3.googleusercontent.com/media",
        }),
      );
    }
    equal(input.hostname, "lh3.googleusercontent.com");
    equal(new Headers(init.headers).has("X-Goog-Api-Key"), false);
    return Promise.resolve(
      new Response(Uint8Array.of(1, 2, 3), {
        headers: { "Content-Type": "image/jpeg" },
      }),
    );
  }) as typeof fetch;
  try {
    equal((await servePhoto(photo, "different-user", apiKey, {})).status, 403);
    equal(
      (await servePhoto(
        { ...photo, expiresAt: Date.now() - 1 },
        user,
        apiKey,
        {},
      )).status,
      400,
    );
    equal(calls, []);
    const success = await servePhoto(photo, user, apiKey, {});
    equal(success.status, 200);
    equal(success.headers.get("cache-control"), "private, no-store");
    equal(Array.from(new Uint8Array(await success.arrayBuffer())), [1, 2, 3]);
    unavailable = true;
    const failure = await servePhoto(photo, user, apiKey, {});
    equal(failure.status, 502);
    equal(await failure.json(), { error: "Photo unavailable" });
    unavailable = false;
    unsafe = true;
    equal((await servePhoto(photo, user, apiKey, {})).status, 502);
    equal(calls, [
      "places.googleapis.com",
      "lh3.googleusercontent.com",
      "places.googleapis.com",
      "places.googleapis.com",
    ]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("photo URLs reject credentials, unsafe hosts, and schemes", () => {
  for (
    const url of [
      "http://lh3.googleusercontent.com/x",
      "https://googleusercontent.com.evil.invalid/x",
      "https://lh3.googleusercontent.com/x?key=secret",
      "https://user:secret@lh3.googleusercontent.com/x",
      "https://lh3.googleusercontent.com:8443/x",
      null,
    ]
  ) equal(safeGooglePhotoUri(url), null);
  equal(
    safeGooglePhotoUri("https://lh3.googleusercontent.com/x"),
    "https://lh3.googleusercontent.com/x",
  );
});
