create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  nickname text,
  avatar_url text,
  onboarding_status text not null default 'new',
  created_at timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);

create table if not exists public.preset_roles (
  id text primary key,
  name text not null,
  species text not null,
  description text not null default '',
  default_personality_tags text[] not null default '{}',
  main_avatar_url text,
  animation_frame_urls text[] not null default '{}',
  thumbnail_url text,
  body_color text,
  shade_color text,
  eye_color text,
  accent_color text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  source_type text not null check (source_type in ('uploaded_photo', 'preset_role')),
  preset_role_id text references public.preset_roles(id),
  name text not null,
  species text,
  avatar_url text,
  source_photo_path text,
  placeholder_avatar_url text,
  final_avatar_url text,
  animation_asset_url text,
  personality_tags text[] not null default '{}',
  special_personality_detail text not null default '',
  mood_value integer not null default 100 check (mood_value between 0 and 100),
  hunger_value integer not null default 100 check (hunger_value between 0 and 100),
  clean_value integer not null default 100 check (clean_value between 0 and 100),
  current_status_text text not null default 'Feeling cozy',
  generation_status text not null default 'none' check (generation_status in ('none', 'generating', 'success', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);

create table if not exists public.generation_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  pet_id uuid references public.pets(id) on delete set null,
  task_type text not null check (task_type in ('avatar_options', 'final_avatar', 'animation_frames')),
  status text not null default 'pending' check (status in ('pending', 'processing', 'success', 'failed')),
  input_photo_path text,
  result_urls text[] not null default '{}',
  selected_result_url text,
  retry_count integer not null default 0,
  max_retry_count integer not null default 2,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pet_memories (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  memory_type text not null check (memory_type in ('user_profile', 'pet_profile', 'recent_event', 'preference')),
  content text not null,
  importance integer not null default 1 check (importance between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  role text not null check (role in ('user', 'pet', 'system')),
  content text not null,
  token_count integer,
  created_at timestamptz not null default now()
);

create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  plan text not null default 'free',
  is_active boolean not null default true,
  source text check (source in ('apple', 'google', 'manual')),
  original_transaction_id text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_preset_roles_updated_at on public.preset_roles;
create trigger set_preset_roles_updated_at
before update on public.preset_roles
for each row execute function public.set_updated_at();

drop trigger if exists set_pets_updated_at on public.pets;
create trigger set_pets_updated_at
before update on public.pets
for each row execute function public.set_updated_at();

drop trigger if exists set_generation_tasks_updated_at on public.generation_tasks;
create trigger set_generation_tasks_updated_at
before update on public.generation_tasks
for each row execute function public.set_updated_at();

drop trigger if exists set_pet_memories_updated_at on public.pet_memories;
create trigger set_pet_memories_updated_at
before update on public.pet_memories
for each row execute function public.set_updated_at();

drop trigger if exists set_entitlements_updated_at on public.entitlements;
create trigger set_entitlements_updated_at
before update on public.entitlements
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (auth_user_id, nickname, onboarding_status)
  values (new.id, coalesce(new.raw_user_meta_data->>'nickname', 'PetPal Friend'), 'new')
  on conflict (auth_user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.users enable row level security;
alter table public.preset_roles enable row level security;
alter table public.pets enable row level security;
alter table public.generation_tasks enable row level security;
alter table public.pet_memories enable row level security;
alter table public.messages enable row level security;
alter table public.entitlements enable row level security;

drop policy if exists "Users can read own profile" on public.users;
create policy "Users can read own profile"
on public.users for select
using (auth.uid() = auth_user_id);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
on public.users for update
using (auth.uid() = auth_user_id)
with check (auth.uid() = auth_user_id);

drop policy if exists "Active preset roles are readable" on public.preset_roles;
create policy "Active preset roles are readable"
on public.preset_roles for select
using (is_active = true);

drop policy if exists "Users can manage own pets" on public.pets;
create policy "Users can manage own pets"
on public.pets for all
using (
  exists (
    select 1 from public.users
    where users.id = pets.user_id
      and users.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.users
    where users.id = pets.user_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can manage own generation tasks" on public.generation_tasks;
create policy "Users can manage own generation tasks"
on public.generation_tasks for all
using (
  exists (
    select 1 from public.users
    where users.id = generation_tasks.user_id
      and users.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.users
    where users.id = generation_tasks.user_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can read own memories" on public.pet_memories;
create policy "Users can read own memories"
on public.pet_memories for select
using (
  exists (
    select 1
    from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = pet_memories.pet_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can read own messages" on public.messages;
create policy "Users can read own messages"
on public.messages for select
using (
  exists (
    select 1
    from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = messages.pet_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can read own entitlements" on public.entitlements;
create policy "Users can read own entitlements"
on public.entitlements for select
using (
  exists (
    select 1 from public.users
    where users.id = entitlements.user_id
      and users.auth_user_id = auth.uid()
  )
);

insert into public.preset_roles (
  id,
  name,
  species,
  description,
  default_personality_tags,
  body_color,
  shade_color,
  eye_color,
  accent_color,
  sort_order,
  is_active
) values
  ('mochi', 'Mochi', 'Orange Cat', 'A playful little foodie with sunny tabby stripes.', array['Playful','Foodie','Affectionate'], '#EF9A3D', '#D3741A', '#7A4E1A', '#F6C79A', 10, true),
  ('luna', 'Luna', 'Calico Cat', 'Soft, sassy, and very good at pretending not to care.', array['Lazy','Sassy','Affectionate'], '#E8C486', '#2F2B2A', '#F0C040', '#E0A0A0', 20, true),
  ('biscuit', 'Biscuit', 'Corgi', 'A bright little dog who believes every sound is snack news.', array['Playful','Chatty','Foodie'], '#B5793F', '#86521F', '#542F16', '#CFA676', 30, true),
  ('shadow', 'Shadow', 'Black Cat', 'Cool, quiet, and secretly very attached.', array['Cool','Sassy','Quiet'], '#3C372F', '#221D17', '#F4C430', '#C89A9A', 40, true),
  ('snowball', 'Snowball', 'White Rabbit', 'Gentle, shy, and fond of quiet mornings.', array['Gentle','Shy','Sweet'], '#F4ECE0', '#DAC9B1', '#9A6B8A', '#F0BCBC', 50, true),
  ('pebble', 'Pebble', 'Tiny Fantasy Pet', 'Curious, strange, and always ready to explore.', array['Curious','Playful','Chatty'], '#9A9CA0', '#65686C', '#3F6285', '#C2C4C6', 60, true)
on conflict (id) do update set
  name = excluded.name,
  species = excluded.species,
  description = excluded.description,
  default_personality_tags = excluded.default_personality_tags,
  body_color = excluded.body_color,
  shade_color = excluded.shade_color,
  eye_color = excluded.eye_color,
  accent_color = excluded.accent_color,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('pet-uploads', 'pet-uploads', false, 10485760, array['image/png','image/jpeg','image/webp']),
  ('pet-avatars', 'pet-avatars', true, 10485760, array['image/png','image/jpeg','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can upload pet source photos" on storage.objects;
create policy "Users can upload pet source photos"
on storage.objects for insert
with check (
  bucket_id = 'pet-uploads'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "Users can read own pet source photos" on storage.objects;
create policy "Users can read own pet source photos"
on storage.objects for select
using (
  bucket_id = 'pet-uploads'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "Pet avatar assets are public" on storage.objects;
create policy "Pet avatar assets are public"
on storage.objects for select
using (bucket_id = 'pet-avatars');
