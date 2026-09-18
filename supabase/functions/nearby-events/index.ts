import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
Deno.serve(async req=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:cors});
  try {
    const auth=req.headers.get('Authorization');
    if(!auth?.startsWith('Bearer ')) return json({error:'Unauthorized'},401);
    const supabase=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:auth}}});
    if(!(await supabase.auth.getUser()).data.user) return json({error:'Unauthorized'},401);
    const b=await req.json(), lat=Number(b.latitude), lon=Number(b.longitude);
    if(!Number.isFinite(lat)||!Number.isFinite(lon)||Math.abs(lat)>90||Math.abs(lon)>180) return json({error:'Invalid location'},400);
    const p=new URLSearchParams({apikey:Deno.env.get('TICKETMASTER_API_KEY')!,latlong:`${lat},${lon}`,radius:'25',unit:'km',size:'20',sort:'date,asc',startDateTime:new Date().toISOString(),endDateTime:new Date(Date.now()+14*86400000).toISOString()});
    const response=await fetch(`https://app.ticketmaster.com/discovery/v2/events.json?${p}`);
    if(!response.ok) return json({error:'Event provider unavailable'},502);
    const data=await response.json();
    return json({events:(data._embedded?.events??[]).map(normalize).filter(Boolean)});
  } catch (_) { return json({error:'Events unavailable'},500); }
});
function normalize(e:any){
  if(typeof e.id!=='string'||typeof e.name!=='string') return null;
  const venue=e._embedded?.venues?.[0], start=e.dates?.start?.dateTime ?? (e.dates?.start?.localDate?`${e.dates.start.localDate}T${e.dates.start.localTime??'00:00:00'}`:null);
  if(!venue?.name||!start) return null;
  const c=e.classifications?.[0], cats=[c?.segment?.name,c?.genre?.name].filter(x=>typeof x==='string');
  const image=e.images?.find((x:any)=>x.ratio==='16_9')??e.images?.[0];
  return {id:`ticketmaster:${e.id}`,title:e.name,venue:venue.name,categories:[...new Set(cats)],description:typeof e.info==='string'?e.info:'A public gathering nearby.',locationLabel:venue.city?.name??null,imageUrl:image?.url??null,imageAttribution:image?.attribution??'Ticketmaster',source:'ticketmaster',sourceUrl:typeof e.url==='string'?e.url:null,startsAt:start,endsAt:e.dates?.end?.dateTime??null,timeLabel:start};
}
function json(body:unknown,status=200){return new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}})}
