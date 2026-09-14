import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const radiusMeters = 2500;
const maxResults = 10;
const includedTypes = [
  "restaurant", "cafe", "bar", "park", "museum", "library",
  "shopping_mall", "stadium", "sports_complex", "tourist_attraction",
  "performing_arts_theater",
];
const fieldMask = "places.id,places.displayName,places.primaryType,places.types,places.shortFormattedAddress,places.location";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const auth = req.headers.get("Authorization");
    if (!auth?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: auth } } });
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "Unauthorized" }, 401);
    const body = await req.json();
    const latitude = Number(body.latitude), longitude = Number(body.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || Math.abs(latitude) > 90 || Math.abs(longitude) > 180) return json({ error: "Invalid location" }, 400);
    const radius = Math.min(Math.max(Number(body.radiusMeters) || radiusMeters, 100), radiusMeters);
    const count = Math.min(Math.max(Number(body.maxResults) || maxResults, 1), maxResults);
    const google = await fetch("https://places.googleapis.com/v1/places:searchNearby", { method: "POST", headers: { "Content-Type": "application/json", "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!, "X-Goog-FieldMask": fieldMask }, body: JSON.stringify({ includedTypes, maxResultCount: count, rankPreference: "DISTANCE", locationRestriction: { circle: { center: { latitude, longitude }, radius } } }) });
    if (!google.ok) return json({ error: "Discovery provider unavailable" }, 502);
    const payload = await google.json();
    const items = (payload.places ?? []).flatMap((place: any) => normalize(place, latitude, longitude));
    return json({ items });
  } catch (_) { return json({ error: "Discovery unavailable" }, 500); }
});

function normalize(place: any, lat: number, lon: number) {
  if (typeof place.id !== "string" || typeof place.displayName?.text !== "string" || !Number.isFinite(place.location?.latitude) || !Number.isFinite(place.location?.longitude)) return [];
  const raw = [place.primaryType, ...(place.types ?? [])].filter((x) => typeof x === "string");
  const categories = [...new Set(raw.flatMap((type: string) => tags[type] ?? []))];
  return [{ id: `google:${place.id}`, title: place.displayName.text, categories, context: typeof place.shortFormattedAddress === "string" ? place.shortFormattedAddress : null, distanceKm: haversine(lat, lon, place.location.latitude, place.location.longitude) }];
}
const tags: Record<string, string[]> = { restaurant: ["food"], cafe: ["food", "social"], bar: ["nightlife", "social"], park: ["outdoors"], museum: ["art"], library: ["education"], shopping_mall: ["shopping"], stadium: ["sports"], sports_complex: ["sports"], tourist_attraction: ["culture"], performing_arts_theater: ["music", "art"] };
function haversine(a: number, b: number, c: number, d: number) { const r = Math.PI / 180, x = (c - a) * r, y = (d - b) * r; const z = Math.sin(x / 2) ** 2 + Math.cos(a * r) * Math.cos(c * r) * Math.sin(y / 2) ** 2; return 6371 * 2 * Math.atan2(Math.sqrt(z), Math.sqrt(1 - z)); }
function json(body: unknown, status = 200) { return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } }); }
