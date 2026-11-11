-- Production execution requires approval. All fixtures and simulated timestamps roll back.
begin;
do $$
declare h jsonb; g jsonb; rid uuid; response jsonb;
begin
  h := public.cratable_create_room('QA_Presence_20261022','','','{}','{}','QA Host');
  rid := (h->>'id')::uuid;
  g := public.cratable_join_room(rid,'QA Guest','');
  perform public.cratable_leave_room(rid,h->>'session_token');
  if (select status from public.rooms where id=rid)='closed' then raise exception 'Host left but guest remains'; end if;
  perform public.cratable_leave_room(rid,h->>'session_token'); -- Retry must be safe.
  response := public.cratable_room_heartbeat(rid,g->>'session_token');
  if not (response->>'active')::boolean then raise exception 'Remaining guest lost session'; end if;
  perform public.cratable_leave_room(rid,g->>'session_token');
  if (select status from public.rooms where id=rid)<>'closed' then raise exception 'Last leave did not close'; end if;

  h := public.cratable_create_room('QA_Presence_20261022','','','{}','{}','QA Host');
  rid := (h->>'id')::uuid;
  g := public.cratable_join_room(rid,'QA Guest','');
  update public.rooms set guest_last_seen=clock_timestamp()-interval '121 seconds' where id=rid;
  perform cratable_private.expire_rooms(rid);
  if (select status from public.rooms where id=rid)<>'waiting' then raise exception 'Expired guest did not free seat'; end if;
  begin
    perform public.cratable_room_heartbeat(rid,'invalid-token');
    raise exception 'Invalid token accepted';
  exception when raise_exception then
    if sqlerrm <> 'Invalid room session' then raise; end if;
  end;
  update public.rooms set host_last_seen=clock_timestamp()-interval '121 seconds' where id=rid;
  perform cratable_private.expire_rooms(rid);
  if (select status from public.rooms where id=rid)<>'closed' then raise exception 'Empty disconnected room not closed'; end if;
  response := public.cratable_room_heartbeat(rid,h->>'session_token');
  if (response->>'active')::boolean then raise exception 'Closed room revived'; end if;
  if has_function_privilege('anon','cratable_private.expire_rooms(uuid)','execute') then raise exception 'Cleanup publicly exposed'; end if;
  if not has_function_privilege('anon','public.cratable_room_heartbeat(uuid,text)','execute') then raise exception 'Heartbeat inaccessible'; end if;
  raise notice 'ROOM_PRESENCE_SQL_PASS';
end $$;
rollback;
