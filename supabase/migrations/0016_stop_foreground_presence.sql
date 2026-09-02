create or replace function public.stop_foreground_presence()
returns void language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'unauthorized'; end if;
  delete from public.presence_evidence
    where subject_user_id = auth.uid() and source = 'geolocation' and expires_at > timezone('utc', now());
end; $$;
revoke all on function public.stop_foreground_presence() from public;
grant execute on function public.stop_foreground_presence() to authenticated;
