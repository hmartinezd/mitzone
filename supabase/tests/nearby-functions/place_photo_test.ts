import {
  placePhoto,
  safeGooglePhotoUri,
} from "../../functions/_shared/place_photo.ts";
function equal(a: unknown, b: unknown) {
  if (JSON.stringify(a) !== JSON.stringify(b)) {
    throw new Error(`Expected ${JSON.stringify(b)}, got ${JSON.stringify(a)}`);
  }
}
const place = {
  id: "fixture",
  photos: [{
    name: "places/fixture/photos/photo",
    authorAttributions: [{ displayName: "Fixture photographer" }],
  }],
};
Deno.test("photo resolves on server without returning API key and retains attribution", async () => {
  let calls = 0;
  const result = await placePhoto(
    place,
    "fixture-key",
    ((url: URL, init: RequestInit) => {
      calls++;
      equal(url.origin, "https://places.googleapis.com");
      equal(url.pathname, "/v1/places/fixture/photos/photo/media");
      equal(url.searchParams.get("skipHttpRedirect"), "true");
      equal(url.searchParams.has("key"), false);
      equal(new Headers(init.headers).get("X-Goog-Api-Key"), "fixture-key");
      equal(init.redirect, "error");
      return Promise.resolve(
        Response.json({
          photoUri: "https://lh3.googleusercontent.com/fixture",
        }),
      );
    }) as typeof fetch,
  );
  equal(calls, 1);
  equal(result, {
    imageReference: "https://lh3.googleusercontent.com/fixture",
    imageAttribution: "Fixture photographer",
  });
  equal(JSON.stringify(result).includes("fixture-key"), false);
});
Deno.test("missing, malformed and mismatched photo resources never call provider", async () => {
  for (
    const input of [{ id: "fixture" }, { ...place, id: "other" }, {
      ...place,
      photos: [{ name: "https://evil.invalid/photo" }],
    }]
  ) {
    let calls = 0;
    equal(
      await placePhoto(
        input,
        "fixture",
        (() => {
          calls++;
          throw new Error("must not call");
        }) as typeof fetch,
      ),
      {},
    );
    equal(calls, 0);
  }
});
Deno.test("upstream failure or malformed image preserves photo fallback", async () => {
  for (
    const response of [
      new Response("", { status: 403 }),
      Response.json({ photoUri: "https://evil.invalid/photo" }),
      Response.json({}),
    ]
  ) {
    equal(
      await placePhoto(
        place,
        "fixture",
        (() => Promise.resolve(response)) as typeof fetch,
      ),
      {},
    );
  }
  equal(
    await placePhoto(
      place,
      "fixture",
      (() => Promise.reject(new Error("fixture failure"))) as typeof fetch,
    ),
    {},
  );
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

Deno.test("photo deadline aborts without taking down places", async () => {
  const timeout = AbortSignal.timeout;
  AbortSignal.timeout = ((ms: number) => {
    equal(ms, 4000);
    return timeout(5);
  }) as typeof AbortSignal.timeout;
  try {
    const result = await placePhoto(
      place,
      "fixture",
      ((_url: URL, init: RequestInit) =>
        new Promise((_resolve, reject) => {
          init.signal!.addEventListener(
            "abort",
            () => reject(init.signal!.reason),
            { once: true },
          );
        })) as typeof fetch,
    );
    equal(result, {});
  } finally {
    AbortSignal.timeout = timeout;
  }
});
