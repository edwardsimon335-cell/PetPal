grant usage on schema public to service_role;

grant select, insert, update on public.users to service_role;
grant select, insert, update on public.generation_tasks to service_role;
