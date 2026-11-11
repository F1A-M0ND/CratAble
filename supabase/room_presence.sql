-- Deployment script: requires explicit production approval and no active legacy rooms.
-- New clients send a token-authenticated heartbeat every 30 seconds.
begin;
lock table public.rooms in share row exclusive mode;
do $$ begin
  if exists(select 1 from public.rooms where status in ('waiting','playing')) then
    raise exception 'Active legacy rooms remain: confirm they are unused before closing and deploying';
  end if;
end $$;
alter table public.rooms add column if not exists host_last_seen timestamptz;
alter table public.rooms add column if not exists guest_last_seen timestamptz;
alter table public.rooms add column if not exists host_left_token_hash text;
alter table public.rooms add column if not exists guest_left_token_hash text;
create schema if not exists cratable_private;
revoke all on schema cratable_private from public, anon, authenticated;

-- Called by the privileged cron worker and token-validated RPCs, never directly by clients.
create or replace function cratable_private.expire_rooms(p_room_id uuid default null)
returns void language plpgsql security invoker set search_path = '' as $$
begin
  update public.rooms set
    host_left_token_hash = case when host_token_hash is not null and (host_last_seen is null or host_last_seen <= clock_timestamp()-interval '120 seconds') then host_token_hash else host_left_token_hash end,
    guest_left_token_hash = case when guest_token_hash is not null and (guest_last_seen is null or guest_last_seen <= clock_timestamp()-interval '120 seconds') then guest_token_hash else guest_left_token_hash end,
    host_token_hash = case when host_last_seen > clock_timestamp()-interval '120 seconds' then host_token_hash else null end,
    guest_token_hash = case when guest_last_seen > clock_timestamp()-interval '120 seconds' then guest_token_hash else null end,
    guest_player = case when guest_last_seen > clock_timestamp()-interval '120 seconds' then guest_player else null end
  where status in ('waiting','playing') and (p_room_id is null or id=p_room_id)
    and ((host_token_hash is not null and (host_last_seen is null or host_last_seen <= clock_timestamp()-interval '120 seconds'))
      or (guest_token_hash is not null and (guest_last_seen is null or guest_last_seen <= clock_timestamp()-interval '120 seconds')));
  update public.rooms set status = case
      when host_token_hash is null and guest_token_hash is null then 'closed'
      when guest_token_hash is null then 'waiting' else 'playing' end
  where status in ('waiting','playing') and (p_room_id is null or id=p_room_id)
    and status is distinct from case
      when host_token_hash is null and guest_token_hash is null then 'closed'
      when guest_token_hash is null then 'waiting' else 'playing' end;
end $$;
revoke all on function cratable_private.expire_rooms(uuid) from public, anon, authenticated;

create or replace function public.cratable_create_room(
  p_name text, p_description text, p_password text, p_field_data jsonb,
  p_deck_data jsonb, p_player text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.rooms; token text := encode(extensions.gen_random_bytes(32), 'hex');
begin
  if coalesce(length(p_name),0) not between 1 and 120
     or coalesce(length(p_player),0) not between 1 and 120
     or octet_length(coalesce(p_password,'')) > 72 then
    raise exception 'Invalid room name, player name or password length';
  end if;
  insert into public.rooms(name,description,password,password_hash,field_data,deck_data,
    host_player,status,host_token_hash,channel_id,host_last_seen)
  values(p_name,p_description,null,
    case when coalesce(p_password,'') = '' then null
      else extensions.crypt(p_password, extensions.gen_salt('bf',10)) end,
    p_field_data,p_deck_data,p_player,'waiting',
    encode(extensions.digest(token,'sha256'),'hex'),encode(extensions.gen_random_bytes(32),'hex'),clock_timestamp())
  returning * into r;
  return (to_jsonb(r) - array['password','password_hash','host_token_hash','guest_token_hash','host_left_token_hash','guest_left_token_hash'])
    || jsonb_build_object('session_token',token);
end $$;

create or replace function public.cratable_join_room(p_room_id uuid, p_player text, p_password text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.rooms; token text := encode(extensions.gen_random_bytes(32),'hex');
begin
  if coalesce(length(p_player),0) not between 1 and 120 or octet_length(coalesce(p_password,'')) > 72 then
    raise exception 'Invalid player name or password length';
  end if;
  -- Lock before checking availability: two guests cannot claim the same room.
  select * into r from public.rooms where id = p_room_id for update;
  if not found or r.status <> 'waiting' or r.host_token_hash is null
     or r.host_last_seen is null or r.host_last_seen <= clock_timestamp() - interval '120 seconds' then
    raise exception 'Room unavailable';
  end if;
  if r.password_hash is not null and
     extensions.crypt(coalesce(p_password,''), r.password_hash) <> r.password_hash then
    raise exception 'Incorrect room password';
  end if;
  update public.rooms set guest_player=p_player, status='playing',
    guest_last_seen=clock_timestamp(), guest_token_hash=encode(extensions.digest(token,'sha256'),'hex')
  where id=p_room_id returning * into r;
  return (to_jsonb(r) - array['password','password_hash','host_token_hash','guest_token_hash','host_left_token_hash','guest_left_token_hash'])
    || jsonb_build_object('session_token',token);
end $$;


create or replace function public.cratable_room_heartbeat(p_room_id uuid, p_token text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.rooms; token_hash text := encode(extensions.digest(coalesce(p_token,''),'sha256'),'hex');
begin
  select * into r from public.rooms where id=p_room_id for update;
  if not found or r.status='closed' then return jsonb_build_object('active',false); end if;
  if token_hash=r.host_left_token_hash or token_hash=r.guest_left_token_hash then
    return jsonb_build_object('active',false);
  end if;
  -- Verify ownership before any maintenance mutation.
  if token_hash is distinct from r.host_token_hash and token_hash is distinct from r.guest_token_hash then
    raise exception 'Invalid room session';
  end if;
  perform cratable_private.expire_rooms(p_room_id);
  select * into r from public.rooms where id=p_room_id;
  if token_hash=r.host_token_hash then
    update public.rooms set host_last_seen=clock_timestamp() where id=p_room_id;
  elsif token_hash=r.guest_token_hash then
    update public.rooms set guest_last_seen=clock_timestamp() where id=p_room_id;
  else return jsonb_build_object('active',false);
  end if;
  return jsonb_build_object('active',true);
end $$;

create or replace function public.cratable_leave_room(p_room_id uuid, p_token text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.rooms; token_hash text := encode(extensions.digest(coalesce(p_token,''),'sha256'),'hex');
begin
  select * into r from public.rooms where id=p_room_id for update;
  if not found or r.status='closed' then return jsonb_build_object('left',true); end if;
  if token_hash=r.host_left_token_hash or token_hash=r.guest_left_token_hash then
    return jsonb_build_object('left',true);
  end if;
  if token_hash=r.host_token_hash then
    update public.rooms set host_left_token_hash=host_token_hash,host_token_hash=null,host_last_seen=null where id=p_room_id;
  elsif token_hash=r.guest_token_hash then
    update public.rooms set guest_left_token_hash=guest_token_hash,guest_player=null,guest_token_hash=null,guest_last_seen=null where id=p_room_id;
  else raise exception 'Invalid room session';
  end if;
  perform cratable_private.expire_rooms(p_room_id);
  return jsonb_build_object('left',true);
end $$;

create or replace function public.cratable_list_rooms()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'description',description,
    'host_player',host_player,'status',status,'has_password',password_hash is not null)), '[]'::jsonb)
  from public.rooms where status='waiting' and host_token_hash is not null
    and host_last_seen > now()-interval '120 seconds';
$$;
revoke all on function public.cratable_room_heartbeat(uuid,text) from public, anon, authenticated;
grant execute on function public.cratable_room_heartbeat(uuid,text) to anon, authenticated;
-- Existing RPC grants remain unchanged. No direct table access is granted.
create extension if not exists pg_cron;
select cron.schedule('cratable-close-empty-rooms','30 seconds',
  'select cratable_private.expire_rooms();');
notify pgrst, 'reload schema';
commit;
