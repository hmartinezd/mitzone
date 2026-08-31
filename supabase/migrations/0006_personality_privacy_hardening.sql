drop policy if exists "users read permitted personality" on public.personality_profiles;
create policy "users read own personality" on public.personality_profiles for select to authenticated using (auth.uid() = user_id);
create or replace function public.get_personality_compatibility(p_other_user_id uuid) returns jsonb language plpgsql security definer set search_path = public as $$
declare me public.personality_profiles; other public.personality_profiles; result numeric;
begin
  if auth.uid() is null or auth.uid() = p_other_user_id then return jsonb_build_object('state','unknown'); end if;
  if not exists (select 1 from public.encounters e where ((e.user_a=auth.uid() and e.user_b=p_other_user_id) or (e.user_b=auth.uid() and e.user_a=p_other_user_id)) and not exists (select 1 from public.blocks b where (b.blocker_user_id=e.user_a and b.blocked_user_id=e.user_b) or (b.blocker_user_id=e.user_b and b.blocked_user_id=e.user_a))) then return jsonb_build_object('state','unknown'); end if;
  select * into me from public.personality_profiles where user_id=auth.uid(); select * into other from public.personality_profiles where user_id=p_other_user_id and visibility='matching';
  if me is null or other is null or me.visibility <> 'matching' then return jsonb_build_object('state','unknown'); end if;
  result := (1-abs((me.traits->>'openness')::numeric-(other.traits->>'openness')::numeric))*.25 + (1-abs((me.traits->>'conscientiousness')::numeric-(other.traits->>'conscientiousness')::numeric))*.2 + (1-abs((me.traits->>'agreeableness')::numeric-(other.traits->>'agreeableness')::numeric))*.25 + (1-abs((me.traits->>'emotionalStability')::numeric-(other.traits->>'emotionalStability')::numeric))*.2 + .5*.1;
  return jsonb_build_object('state','known','value',greatest(0,least(1,result)));
end; $$;
revoke all on function public.get_personality_compatibility(uuid) from public; grant execute on function public.get_personality_compatibility(uuid) to authenticated;
