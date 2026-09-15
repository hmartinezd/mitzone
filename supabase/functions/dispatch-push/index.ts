import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
let cached: { token: string; until: number } | undefined;
const b64 = (b: Uint8Array) => { let s=''; for (const x of b) s += String.fromCharCode(x); return btoa(s).replaceAll('+','-').replaceAll('/','_').replaceAll('=',''); };
async function getAccessToken(): Promise<string> {
  if (cached && cached.until > Date.now() + 60000) return cached.token;
  const email=Deno.env.get('FCM_CLIENT_EMAIL'), configured=Deno.env.get('FCM_PRIVATE_KEY');
  if (!email || !configured) throw new Error('FCM service account is not configured');
  const pem=configured.replaceAll('\\n','\n'), der=pem.replace(/-----[^-]+-----|\s/g,'');
  const key=await crypto.subtle.importKey('pkcs8', Uint8Array.from(atob(der), c=>c.charCodeAt(0)), {name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'}, false, ['sign']);
  const now=Math.floor(Date.now()/1000), enc=new TextEncoder();
  const head=b64(enc.encode(JSON.stringify({alg:'RS256',typ:'JWT'}))), claim=b64(enc.encode(JSON.stringify({iss:email,scope:SCOPE,aud:TOKEN_URL,iat:now,exp:now+3600})));
  const unsigned=`${head}.${claim}`, sig=await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key,enc.encode(unsigned));
  const response=await fetch(TOKEN_URL,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion:`${unsigned}.${b64(new Uint8Array(sig))}`})});
  if(!response.ok) throw new Error(`FCM OAuth token request failed (${response.status})`);
  const result=await response.json(); if(typeof result.access_token!=='string') throw new Error('FCM OAuth response missing access token');
  cached={token:result.access_token,until:Date.now()+Number(result.expires_in??3600)*1000}; return cached.token;
}

// Invoked by a Supabase Database Webhook for INSERT on public.notifications.
// The webhook must send only { record: { id } }; recipient/message data is resolved here.
Deno.serve(async (req) => {
  const body = await req.json();
  if (body?.type !== 'INSERT' || body?.table !== 'notifications' || body?.schema !== 'public') return new Response('ignored', { status: 202 });
  const id = body?.record?.id;
  if (!id) return new Response('missing notification id', { status: 400 });
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: n } = await admin.from('notifications').select('id,recipient_user_id,actor_user_id,type,entity_id').eq('id', id).single();
  if (!n || !n.recipient_user_id || !['connectionRequest','connectionAccepted','newMessage'].includes(n.type)) return new Response('ignored', { status: 202 });
  if (n.actor_user_id) { const { data: blocked } = await admin.from('blocks').select('id').or(`and(blocker_user_id.eq.${n.actor_user_id},blocked_user_id.eq.${n.recipient_user_id}),and(blocker_user_id.eq.${n.recipient_user_id},blocked_user_id.eq.${n.actor_user_id})`).limit(1); if (blocked?.length) return new Response('ignored',{status:202}); }
  const { data: tokens } = await admin.from('device_tokens').select('id,token').eq('user_id', n.recipient_user_id);
  const title = 'Mitzone';
  const bodyText = n.type === 'connectionRequest' ? 'Someone wants to connect with you.' : n.type === 'connectionAccepted' ? 'Your connection request was accepted.' : 'You have a new message.';
  const projectId = Deno.env.get('FCM_PROJECT_ID');
  if (!projectId) return new Response('FCM not configured', { status: 503 });
  let accessToken: string; try { accessToken = await getAccessToken(); } catch (error) { console.error(error instanceof Error ? error.message : 'FCM authentication failed'); return new Response('FCM not configured',{status:503}); }
  for (const t of tokens ?? []) {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ message: { token: t.token, notification: { title, body: bodyText }, data: { type: n.type, entityId: n.entity_id ?? '' } } }) });
    if (response.status === 404 || response.status === 410 || (response.status === 400 && (await response.clone().text()).includes('UNREGISTERED'))) await admin.from('device_tokens').delete().eq('id', t.id);
  }
  return new Response('ok');
});
