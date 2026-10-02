-- Read-only. Run before the migration; never select password/key/token contents.
select column_name, data_type, udt_name, is_nullable, column_default
from information_schema.columns where table_schema='public' and table_name='rooms'
order by ordinal_position;
select conname, pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid='public.rooms'::regclass;
select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies where schemaname='public' and tablename='rooms';
select grantee, privilege_type from information_schema.role_table_grants
where table_schema='public' and table_name='rooms';
select status, count(*) as count from public.rooms
where name <> 'QA_CratAble_20261002' and status in ('waiting','playing') group by status;
select extname, extnamespace::regnamespace as schema from pg_extension where extname='pgcrypto';
select n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and (p.proname like 'cratable_%' or p.prosrc ilike '%rooms%');
