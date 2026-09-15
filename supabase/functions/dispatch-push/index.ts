import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Invoked by a Supabase Database Webhook for INSERT on public.notifications.
// The webhook must send only { record: { id } }; recipient/message data is resolved here.
Deno.serve(async (req) => {
  const body = await req.json();
  if (body?.type !== 'INSERT' || body?.table !== 'notifications' || body?.schema !== 'public') return new Response('ignored', { status: 202 });
  const id = body?.record?.id;
  if (!id) return new Response('missing notification id', { status: 400 });
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: n } = await admin.from('notifications').select('id,recipient_user_id,type,entity_id').eq('id', id).single();
  if (!n || !n.recipient_user_id || !['connectionRequest','connectionAccepted','newMessage'].includes(n.type)) return new Response('ignored', { status: 202 });
  const { data: tokens } = await admin.from('device_tokens').select('id,token').eq('user_id', n.recipient_user_id);
  const title = 'Mitzone';
  const bodyText = n.type === 'connectionRequest' ? 'Someone wants to connect with you.' : n.type === 'connectionAccepted' ? 'Your connection request was accepted.' : 'You have a new message.';
  const accessToken = Deno.env.get('FCM_ACCESS_TOKEN');
  const projectId = Deno.env.get('FCM_PROJECT_ID');
  if (!accessToken || !projectId) return new Response('FCM not configured', { status: 503 });
  for (const t of tokens ?? []) {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, { method: 'POST', headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ message: { token: t.token, notification: { title, body: bodyText }, data: { type: n.type, entityId: n.entity_id ?? '' } } }) });
    if (response.status === 404 || response.status === 410) await admin.from('device_tokens').delete().eq('id', t.id);
  }
  return new Response('ok');
});
