import { auth } from "./supabase_mock.ts";

function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("nearby-events offline authentication, privacy and response contracts", async (t) => {
  const originalServe = Deno.serve;
  const originalGet = Deno.env.get;
  const originalFetch = globalThis.fetch;
  const originalError = console.error;
  let handler: (request: Request) => Response | Promise<Response>;
  const env: Record<string, string> = {
    SUPABASE_URL: "https://example.invalid",
    SUPABASE_ANON_KEY: "test-anon",
    TICKETMASTER_API_KEY: "  test-provider-key  ",
  };
  let calls: URL[] = [];
  let logs: unknown[][] = [];
  let upstreamStatus = 200;
  let upstreamBody = "{}";
  let networkFailure = false;
  Deno.serve = ((callback: typeof handler) => {
    handler = callback;
  }) as typeof Deno.serve;
  Deno.env.get = ((key: string) => env[key]) as typeof Deno.env.get;
  console.error = (...args: unknown[]) => {
    logs.push(args);
  };
  globalThis.fetch = ((input: string | URL | Request) => {
    const url = new URL(input instanceof Request ? input.url : input);
    calls.push(url);
    if (url.origin !== "https://app.ticketmaster.com") {
      throw new Error("Unexpected destination");
    }
    if (networkFailure) {
      return Promise.reject(new Error("simulated network failure"));
    }
    return Promise.resolve(
      new Response(upstreamBody, { status: upstreamStatus }),
    );
  }) as typeof fetch;
  const request = (
    body: unknown = { latitude: 27.9506, longitude: -82.4572 },
    token: string | null = "Bearer test-token",
  ) =>
    new Request("https://example.invalid/nearby-events", {
      method: "POST",
      headers: token ? { Authorization: token } : {},
      body: JSON.stringify(body),
    });
  const run = async (req = request()) => {
    const response = await handler(req);
    equal(response.headers.get("Access-Control-Allow-Origin"), "*");
    equal(response.headers.get("Content-Type"), "application/json");
    return { status: response.status, body: await response.json() };
  };
  try {
    // Execute the actual deployment entrypoint; only its external boundaries are mocked.
    await import("../../functions/nearby-events/index.ts");
    await t.step("CORS preflight needs no auth or provider call", async () => {
      const result = await handler(
        new Request("https://example.invalid", { method: "OPTIONS" }),
      );
      equal(result.status, 200);
      equal(await result.text(), "ok");
      equal(calls.length, 0);
      equal(auth.calls, 0);
    });
    for (const token of [null, "Basic test"]) {
      await t.step(
        `rejects missing or malformed bearer: ${
          token === null ? "missing" : "malformed"
        }`,
        async () => {
          equal(await run(request(undefined, token)), {
            status: 401,
            body: { error: "Unauthorized" },
          });
          equal(calls.length, 0);
          equal(auth.calls, 0);
        },
      );
    }
    await t.step(
      "invalid authenticated user cannot query provider",
      async () => {
        auth.valid = false;
        equal(await run(), { status: 401, body: { error: "Unauthorized" } });
        equal(calls.length, 0);
        auth.valid = true;
      },
    );
    for (
      const body of [{ latitude: 91, longitude: 0 }, {
        latitude: 0,
        longitude: -181,
      }, { latitude: "invalid", longitude: 0 }]
    ) {
      await t.step(
        `invalid coordinate rejected: ${JSON.stringify(body)}`,
        async () => {
          equal(await run(request(body)), {
            status: 400,
            body: { error: "Invalid location" },
          });
          equal(calls.length, 0);
        },
      );
    }
    for (const key of ["", "   "]) {
      await t.step(
        "missing or whitespace key returns 503 without fetch",
        async () => {
          env.TICKETMASTER_API_KEY = key;
          equal(await run(), {
            status: 503,
            body: { error: "Event provider not configured" },
          });
          equal(calls.length, 0);
        },
      );
    }
    env.TICKETMASTER_API_KEY = "  test-provider-key  ";
    await t.step(
      "valid request preserves bounds, UTC seconds and privacy",
      async () => {
        const before = Date.now();
        equal(await run(), { status: 200, body: { events: [] } });
        equal(auth.authorization, "Bearer test-token");
        const url = calls[0];
        equal(url.pathname, "/discovery/v2/events.json");
        const query = Object.fromEntries(url.searchParams);
        equal(
          Object.keys(query).sort(),
          [
            "apikey",
            "endDateTime",
            "latlong",
            "radius",
            "size",
            "sort",
            "startDateTime",
            "unit",
          ].sort(),
        );
        equal(query.apikey, "test-provider-key");
        equal(query.latlong, "27.9506,-82.4572");
        equal([query.radius, query.size, query.sort, query.unit], [
          "25",
          "20",
          "date,asc",
          "km",
        ]);
        for (const key of ["startDateTime", "endDateTime"]) {
          equal(
            /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(query[key]),
            true,
          );
        }
        equal(Math.abs(Date.parse(query.startDateTime) - before) < 1500, true);
        equal(
          Math.abs(
            Date.parse(query.endDateTime) - Date.parse(query.startDateTime) -
              14 * 86400000,
          ) <= 1000,
          true,
        );
      },
    );
    for (const status of [400, 401, 403, 429, 500, 503]) {
      await t.step(
        `provider ${status} preserves 502 contract and safe diagnostic`,
        async () => {
          upstreamStatus = status;
          logs = [];
          equal(await run(), {
            status: 502,
            body: {
              error: "Event provider unavailable",
              providerStatus: status,
            },
          });
          equal(logs, [["Ticketmaster request failed", { status }]]);
        },
      );
    }
    upstreamStatus = 200;
    await t.step(
      "normalized event fields and source/photo attribution stay compatible",
      async () => {
        upstreamBody = JSON.stringify({
          _embedded: {
            events: [{
              id: "e1",
              name: "Real provider fixture",
              _embedded: {
                venues: [{ name: "Venue", city: { name: "Tampa" } }],
              },
              dates: { start: { dateTime: "2026-10-15T20:00:00Z" } },
              classifications: [{
                segment: { name: "Music" },
                genre: { name: "Music" },
              }],
              images: [{
                ratio: "16_9",
                url: "https://example.invalid/photo.jpg",
                attribution: "Photographer",
              }],
              url: "https://example.invalid/event",
              info: "Description",
            }, { id: "incomplete", name: "Missing venue" }],
          },
        });
        equal(await run(), {
          status: 200,
          body: {
            events: [{
              id: "ticketmaster:e1",
              title: "Real provider fixture",
              venue: "Venue",
              categories: ["Music"],
              description: "Description",
              locationLabel: "Tampa",
              imageUrl: "https://example.invalid/photo.jpg",
              imageAttribution: "Photographer",
              source: "ticketmaster",
              sourceUrl: "https://example.invalid/event",
              startsAt: "2026-10-15T20:00:00Z",
              endsAt: null,
              timeLabel: "2026-10-15T20:00:00Z",
            }],
          },
        });
      },
    );
    for (const body of ["not-json", '{"_embedded":{"events":{}}}']) {
      await t.step(
        "invalid upstream payload preserves sanitized 500",
        async () => {
          upstreamBody = body;
          equal(await run(), {
            status: 500,
            body: { error: "Events unavailable" },
          });
        },
      );
    }
    await t.step("network failure preserves sanitized 500", async () => {
      networkFailure = true;
      equal(await run(), {
        status: 500,
        body: { error: "Events unavailable" },
      });
    });
  } finally {
    Deno.serve = originalServe;
    Deno.env.get = originalGet;
    globalThis.fetch = originalFetch;
    console.error = originalError;
  }
});
