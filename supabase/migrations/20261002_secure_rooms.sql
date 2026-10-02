-- REVIEW REQUIRED: run in a maintenance window after all real rooms have closed.
-- The updated client requires these RPCs. Older clients lose direct rooms access.
-- No cards/decks/fields policies or data are changed. Transactional migration.
begin;
create extension if not exists pgcrypto with schema extensions;
do $$ begin
  if exists (select 1 from public.rooms where status in ('waiting','playing')
    and name <> 'QA_CratAble_20261002') then
    raise exception 'Close active real rooms before applying this migration';
  end if;
end $$;

alter table public.rooms add column if not exists password_hash text;
alter table public.rooms add column if not exists host_token_hash text;
alter table public.rooms add column if not exists guest_token_hash text;
alter table public.rooms add column if not exists channel_id text;
update public.rooms set password_hash = extensions.crypt(password, extensions.gen_salt('bf', 10))
where nullif(password, '') is not null and password_hash is null;
update public.rooms set password = null where password is not null;

-- Remove table AND column grants; RLS alone cannot override permissive policies.
revoke all privileges on table public.rooms from public, anon, authenticated;
do $$ declare col record; begin
  for col in select column_name from information_schema.columns
    where table_schema='public' and table_name='rooms' loop
    execute format('revoke select (%I), insert (%I), update (%I), references (%I) on public.rooms from public, anon, authenticated',
      col.column_name, col.column_name, col.column_name, col.column_name);
  end loop;
end $$;
alter table public.rooms enable row level security;

create or replace function public.cratable_list_rooms()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'name', name,
    'description', description, 'host_player', host_player, 'status', status,
    'has_password', password_hash is not null)), '[]'::jsonb)
  from public.rooms where status = 'waiting' and host_token_hash is not null;
$$;

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
    host_player,status,host_token_hash,channel_id)
  values(p_name,p_description,null,
    case when coalesce(p_password,'') = '' then null
      else extensions.crypt(p_password, extensions.gen_salt('bf',10)) end,
    p_field_data,p_deck_data,p_player,'waiting',
    encode(extensions.digest(token,'sha256'),'hex'),encode(extensions.gen_random_bytes(32),'hex'))
  returning * into r;
  return (to_jsonb(r) - array['password','password_hash','host_token_hash','guest_token_hash'])
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
  if not found or r.status <> 'waiting' or r.host_token_hash is null then
    raise exception 'Room unavailable';
  end if;
  if r.password_hash is not null and
     extensions.crypt(coalesce(p_password,''), r.password_hash) <> r.password_hash then
    raise exception 'Incorrect room password';
  end if;
  update public.rooms set guest_player=p_player, status='playing',
    guest_token_hash=encode(extensions.digest(token,'sha256'),'hex')
  where id=p_room_id returning * into r;
  return (to_jsonb(r) - array['password','password_hash','host_token_hash','guest_token_hash'])
    || jsonb_build_object('session_token',token);
end $$;

create or replace function public.cratable_leave_room(p_room_id uuid, p_token text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.rooms; token_hash text := encode(extensions.digest(coalesce(p_token,''),'sha256'),'hex');
begin
  select * into r from public.rooms where id=p_room_id for update;
  if not found then return jsonb_build_object('left',true); end if;
  if token_hash=r.host_token_hash then
    update public.rooms set status='closed',guest_player=null,guest_token_hash=null where id=p_room_id;
  elsif token_hash=r.guest_token_hash and r.status <> 'closed' then
    update public.rooms set status='waiting',guest_player=null,guest_token_hash=null where id=p_room_id;
  else
    raise exception 'Invalid room session';
  end if;
  return jsonb_build_object('left',true);
end $$;

revoke all on function public.cratable_list_rooms() from public, anon, authenticated;
revoke all on function public.cratable_create_room(text,text,text,jsonb,jsonb,text) from public, anon, authenticated;
revoke all on function public.cratable_join_room(uuid,text,text) from public, anon, authenticated;
revoke all on function public.cratable_leave_room(uuid,text) from public, anon, authenticated;
grant execute on function public.cratable_list_rooms() to anon, authenticated;
grant execute on function public.cratable_create_room(text,text,text,jsonb,jsonb,text) to anon, authenticated;
grant execute on function public.cratable_join_room(uuid,text,text) to anon, authenticated;
grant execute on function public.cratable_leave_room(uuid,text) to anon, authenticated;
notify pgrst, 'reload schema';
commit;
