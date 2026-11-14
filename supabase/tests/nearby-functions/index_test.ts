import { nearbyCoordinates } from "../../functions/_shared/nearby_request.ts";
import { auth } from "../nearby-events/supabase_mock.ts";

function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("both nearby entrypoints reject coerced coordinates and abort stalled providers", async (t) => {
  const originalServe = Deno.serve;
  const originalGet = Deno.env.get;
  const originalFetch = globalThis.fetch;
  const originalTimeout = AbortSignal.timeout;
  let handler: (request: Request) => Response | Promise<Response>;
  let calls = 0;
  let mode: "normal" | "headers-stall" | "body-stall" = "normal";
  let signal: AbortSignal;
  const env: Record<string, string> = {
    SUPABASE_URL: "https://example.invalid",
    SUPABASE_ANON_KEY: "fixture-only",
    GOOGLE_PLACES_API_KEY: "fixture-places-key",
    TICKETMASTER_API_KEY: "fixture-events-key",
  };
  Deno.serve = ((callback: typeof handler) => {
    handler = callback;
  }) as typeof Deno.serve;
  Deno.env.get = ((key: string) => env[key]) as typeof Deno.env.get;
  // Accelerate only the deadline; still exercise each real fetch signal and handler.
  AbortSignal.timeout = ((milliseconds: number) => {
    equal(milliseconds, 10_000);
    const controller = new AbortController();
    signal = controller.signal;
    if (mode !== "normal") {
      setTimeout(
        () =>
          controller.abort(new DOMException("fixture timeout", "TimeoutError")),
        5,
      );
    }
    return signal;
  }) as typeof AbortSignal.timeout;
  globalThis.fetch = ((input: string | URL | Request, init?: RequestInit) => {
    calls++;
    const url = new URL(input instanceof Request ? input.url : input);
    equal(
      ["https://places.googleapis.com", "https://app.ticketmaster.com"]
        .includes(url.origin),
      true,
    );
    equal(init?.signal, signal);
    equal(new Headers(init?.headers).has("Authorization"), false);
    if (mode === "headers-stall") {
      return new Promise<Response>((_resolve, reject) => {
        signal.addEventListener("abort", () => reject(signal.reason), {
          once: true,
        });
      });
    }
    if (mode === "body-stall") {
      return Promise.resolve(
        new Response(
          new ReadableStream({
            start(controller) {
              signal.addEventListener(
                "abort",
                () => controller.error(signal.reason),
                { once: true },
              );
            },
          }),
        ),
      );
    }
    return Promise.resolve(new Response("{}"));
  }) as typeof fetch;
  const run = async (body: unknown, bearer = "Bearer fixture-session") => {
    const response = await handler(
      new Request("https://example.invalid/discovery", {
        method: "POST",
        headers: { Authorization: bearer },
        body: JSON.stringify(body),
      }),
    );
    return { status: response.status, body: await response.json() };
  };
  try {
    for (
      const [name, path, resultKey, safeError] of [
        [
          "places",
          "../../functions/nearby-discovery/index.ts",
          "items",
          "Discovery unavailable",
        ],
        [
          "events",
          "../../functions/nearby-events/index.ts",
          "events",
          "Events unavailable",
        ],
      ]
    ) {
      await import(path);
      for (
        const body of [
          null,
          [],
          {},
          { latitude: 0 },
          { longitude: 0 },
          ...[null, "", " ", "0", true, false, [], {}, "NaN", "Infinity"]
            .flatMap((value) => [
              { latitude: value, longitude: 0 },
              { latitude: 0, longitude: value },
            ]),
          { latitude: 90.01, longitude: 0 },
          { latitude: 0, longitude: -180.01 },
        ]
      ) {
        await t.step(
          `${name}: rejects ${JSON.stringify(body)} without provider call`,
          async () => {
            const before = calls;
            equal(await run(body), {
              status: 400,
              body: { error: "Invalid location" },
            });
            equal(calls, before);
          },
        );
      }
      await t.step(
        `${name}: rejects invalid user before provider`,
        async () => {
          auth.valid = false;
          const before = calls;
          equal(await run({ latitude: 0, longitude: 0 }), {
            status: 401,
            body: { error: "Unauthorized" },
          });
          equal(calls, before);
          auth.valid = true;
        },
      );
      for (
        const [latitude, longitude] of [[0, 0], [90, 180], [-90, -180], [
          40.7484,
          -73.9857,
        ]]
      ) {
        await t.step(
          `${name}: accepts numeric boundary ${latitude},${longitude}`,
          async () => {
            equal(await run({ latitude, longitude }), {
              status: 200,
              body: { [resultKey]: [] },
            });
          },
        );
      }
      for (const stalled of ["headers-stall", "body-stall"] as const) {
        await t.step(
          `${name}: aborts ${stalled} with sanitized response`,
          async () => {
            mode = stalled;
            equal(await run({ latitude: 0, longitude: 0 }), {
              status: 500,
              body: { error: safeError },
            });
            equal(signal.aborted, true);
            mode = "normal";
          },
        );
      }
    }
  } finally {
    Deno.serve = originalServe;
    Deno.env.get = originalGet;
    globalThis.fetch = originalFetch;
    AbortSignal.timeout = originalTimeout;
    auth.valid = true;
  }
});

Deno.test("coordinate validator rejects non-finite numbers and preserves valid values", () => {
  for (const value of [NaN, Infinity, -Infinity]) {
    equal(nearbyCoordinates({ latitude: value, longitude: 0 }), null);
    equal(nearbyCoordinates({ latitude: 0, longitude: value }), null);
  }
  equal(nearbyCoordinates({ latitude: 0, longitude: -180 }), {
    latitude: 0,
    longitude: -180,
  });
});
