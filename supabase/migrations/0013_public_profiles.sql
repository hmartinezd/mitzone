create or replace function public.get_public_profiles(p_user_ids uuid[])
returns table(id uuid, display_name text, avatar_uri text, bio text, city text)
language sql security definer set search_path = public
as $$
  select p.id, p.display_name, p.avatar_uri, p.bio, p.city
  from public.profiles p
  where p.id = any(p_user_ids)
    and (p.id = auth.uid() or exists (
      select 1 from public.encounters e where (e.user_a=auth.uid() and e.user_b=p.id) or (e.user_b=auth.uid() and e.user_a=p.id)
      union all select 1 from public.connections c where (c.user_a_id=auth.uid() and c.user_b_id=p.id) or (c.user_b_id=auth.uid() and c.user_a_id=p.id)
      union all select 1 from public.connection_requests r where (r.sender_user_id=auth.uid() and r.recipient_user_id=p.id) or (r.recipient_user_id=auth.uid() and r.sender_user_id=p.id)
    ) and not exists (select 1 from public.blocks b where (b.blocker_user_id=auth.uid() and b.blocked_user_id=p.id) or (b.blocker_user_id=p.id and b.blocked_user_id=auth.uid())));
$$;
revoke all on function public.get_public_profiles(uuid[]) from public;
grant execute on function public.get_public_profiles(uuid[]) to authenticated;
