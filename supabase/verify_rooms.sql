-- Run only after schema review + approval + migration.
-- All test changes are rolled back, including the replacement of the old QA row.
begin;
delete from public.rooms where id='2584f955-984e-447a-b3fd-b49274459896'::uuid
  and name='QA_CratAble_20261002';
set local role anon;
do $$
declare host_room jsonb; guest_room jsonb; listed jsonb; result jsonb; room_id uuid;
begin
  host_room := public.cratable_create_room('QA_CratAble_20261002','Transactional regression',
    'qa-password', '{}'::jsonb, '{}'::jsonb, 'QA_Host');
  room_id := (host_room->>'id')::uuid;
  if host_room ?| array['password','password_hash','host_token_hash','guest_token_hash']
     or length(host_room->>'session_token') <> 64 then raise exception 'TEST: secret response'; end if;
  listed := public.cratable_list_rooms();
  if not exists(select 1 from jsonb_array_elements(listed) r where r->>'id'=room_id::text
    and (r->>'has_password')::boolean and not (r ?| array['password','password_hash','channel_id','session_token','field_data'])) then
    raise exception 'TEST: unsafe/missing room listing';
  end if;
  begin
    perform 1 from public.rooms limit 1;
    raise exception 'TEST: direct table read still allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.rooms set guest_player='Bypass' where id=room_id;
    raise exception 'TEST: direct table update still allowed';
  exception when insufficient_privilege then null; end;
  begin
    perform public.cratable_join_room(room_id,'QA_Guest','wrong');
    raise exception 'TEST: incorrect password accepted';
  exception when others then
    if sqlerrm <> 'Incorrect room password' then raise; end if;
  end;
  guest_room := public.cratable_join_room(room_id,'QA_Guest','qa-password');
  if guest_room->>'status' <> 'playing' or guest_room->>'channel_id' <> host_room->>'channel_id'
    or guest_room->>'session_token' = host_room->>'session_token' then raise exception 'TEST: join response'; end if;
  begin
    perform public.cratable_join_room(room_id,'ThirdGuest','qa-password');
    raise exception 'TEST: occupied room accepted another guest';
  exception when others then
    if sqlerrm <> 'Room unavailable' then raise; end if;
  end;
  begin
    perform public.cratable_leave_room(room_id,'invalid-token');
    raise exception 'TEST: invalid session closed room';
  exception when others then
    if sqlerrm <> 'Invalid room session' then raise; end if;
  end;
  result := public.cratable_leave_room(room_id,guest_room->>'session_token');
  listed := public.cratable_list_rooms();
  if not exists(select 1 from jsonb_array_elements(listed) r where r->>'id'=room_id::text) then
    raise exception 'TEST: guest leave did not reopen room';
  end if;
  result := public.cratable_leave_room(room_id,host_room->>'session_token');
  listed := public.cratable_list_rooms();
  if exists(select 1 from jsonb_array_elements(listed) r where r->>'id'=room_id::text) then
    raise exception 'TEST: host leave did not close room';
  end if;
  raise notice 'ROOM_RPC_REGRESSION: passed';
end $$;
rollback;
