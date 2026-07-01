alter table public.pets
  add column if not exists last_offline_event_at timestamptz,
  add column if not exists offline_event_show_count_today integer not null default 0 check (offline_event_show_count_today >= 0),
  add column if not exists shown_event_ids_today text[] not null default '{}',
  add column if not exists placed_item_ids text[] not null default '{}',
  add column if not exists last_room_item_update_at timestamptz;

create table if not exists public.room_item_configs (
  item_id text primary key,
  item_name text not null,
  item_type text not null,
  pet_type text not null default 'all',
  icon_url text,
  room_asset_url text,
  default_room_asset_url text,
  description text not null default '',
  unlock_affinity_level integer not null default 1,
  default_unlocked boolean not null default false,
  display_order integer not null default 0,
  enabled boolean not null default true,
  archived boolean not null default false,
  min_app_version text,
  max_app_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.offline_event_configs (
  event_id text primary key,
  event_name text not null,
  event_type text not null,
  pet_type text not null default 'all',
  personality_tags text[] not null default '{}',
  required_item text,
  related_items text[] not null default '{}',
  item_weight_bonus integer not null default 0,
  time_window text[] not null default '{all}',
  preferred_time_window text[] not null default '{}',
  offline_min_minutes integer not null default 120,
  offline_max_minutes integer,
  mood_min integer,
  mood_max integer,
  hunger_min integer,
  hunger_max integer,
  affinity_min_level integer not null default 1,
  base_weight integer not null default 1,
  reward_mood integer not null default 0,
  reward_hunger integer not null default 0,
  reward_affinity integer not null default 0,
  can_unlock_moment boolean not null default false,
  moment_id text,
  once_per_pet boolean not null default false,
  title_template text not null,
  body_template text not null,
  image_key text not null default 'default',
  enabled boolean not null default true,
  archived boolean not null default false,
  min_app_version text,
  max_app_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.moment_configs (
  moment_id text primary key,
  title text not null,
  moment_type text not null default 'home',
  image_url text,
  thumbnail_url text,
  default_image_url text,
  diary_template text not null,
  pet_type text not null default 'all',
  source_type text not null default 'offline_event',
  display_order integer not null default 0,
  enabled boolean not null default true,
  archived boolean not null default false,
  min_app_version text,
  max_app_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_moment_records (
  moment_record_id text primary key,
  moment_id text not null,
  pet_id uuid not null references public.pets(id) on delete cascade,
  source_event_id text not null,
  title_snapshot text not null,
  diary_text_snapshot text not null,
  image_url_snapshot text not null default '',
  moment_type_snapshot text not null default 'home',
  created_at timestamptz not null default now(),
  is_favorite boolean not null default false,
  deleted_at timestamptz
);

create table if not exists public.offline_event_history (
  history_id text primary key,
  pet_id uuid not null references public.pets(id) on delete cascade,
  event_id text not null,
  event_type text not null,
  triggered_at timestamptz not null default now(),
  offline_duration_minutes integer not null default 0,
  mood_before integer not null default 0,
  hunger_before integer not null default 0,
  affinity_before integer not null default 0,
  mood_after integer not null default 0,
  hunger_after integer not null default 0,
  affinity_after integer not null default 0,
  placed_item_ids_snapshot text[] not null default '{}',
  moment_saved boolean not null default false,
  moment_record_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.moment_assets (
  asset_id text primary key default gen_random_uuid()::text,
  pet_id uuid references public.pets(id) on delete cascade,
  role_id text,
  moment_id text not null,
  event_id text,
  image_key text,
  source_type text not null default 'ai' check (source_type in ('static', 'ai')),
  image_url text not null,
  thumbnail_url text,
  status text not null default 'ready' check (status in ('ready', 'generating', 'failed')),
  prompt text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (pet_id, moment_id)
);

create table if not exists public.moment_generation_tasks (
  task_id text primary key default gen_random_uuid()::text,
  pet_id uuid not null references public.pets(id) on delete cascade,
  moment_id text not null,
  event_id text not null,
  pending_id text,
  status text not null default 'pending' check (status in ('pending', 'processing', 'success', 'failed')),
  prompt text not null,
  result_asset_id text,
  result_url text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pending_moment_events (
  pending_id text primary key,
  pet_id uuid not null references public.pets(id) on delete cascade,
  event_id text not null,
  moment_id text not null,
  triggered_at timestamptz not null default now(),
  offline_duration_minutes integer not null default 0,
  mood_before integer not null default 0,
  hunger_before integer not null default 0,
  affinity_before integer not null default 0,
  placed_item_ids_snapshot text[] not null default '{}',
  generation_status text not null default 'pending' check (generation_status in ('pending', 'generating', 'ready', 'failed')),
  generation_task_id text,
  image_url text,
  last_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (pet_id, event_id, moment_id)
);

create unique index if not exists user_moment_records_one_active_moment
on public.user_moment_records (pet_id, moment_id)
where deleted_at is null;

create index if not exists user_moment_records_pet_created_idx
on public.user_moment_records (pet_id, created_at desc);

create index if not exists offline_event_history_pet_triggered_idx
on public.offline_event_history (pet_id, triggered_at desc);

create index if not exists moment_assets_pet_moment_idx
on public.moment_assets (pet_id, moment_id);

create index if not exists moment_generation_tasks_pet_created_idx
on public.moment_generation_tasks (pet_id, created_at desc);

create index if not exists pending_moment_events_pet_created_idx
on public.pending_moment_events (pet_id, created_at desc);

drop trigger if exists set_room_item_configs_updated_at on public.room_item_configs;
create trigger set_room_item_configs_updated_at
before update on public.room_item_configs
for each row execute function public.set_updated_at();

drop trigger if exists set_offline_event_configs_updated_at on public.offline_event_configs;
create trigger set_offline_event_configs_updated_at
before update on public.offline_event_configs
for each row execute function public.set_updated_at();

drop trigger if exists set_moment_configs_updated_at on public.moment_configs;
create trigger set_moment_configs_updated_at
before update on public.moment_configs
for each row execute function public.set_updated_at();

drop trigger if exists set_moment_assets_updated_at on public.moment_assets;
create trigger set_moment_assets_updated_at
before update on public.moment_assets
for each row execute function public.set_updated_at();

drop trigger if exists set_moment_generation_tasks_updated_at on public.moment_generation_tasks;
create trigger set_moment_generation_tasks_updated_at
before update on public.moment_generation_tasks
for each row execute function public.set_updated_at();

drop trigger if exists set_pending_moment_events_updated_at on public.pending_moment_events;
create trigger set_pending_moment_events_updated_at
before update on public.pending_moment_events
for each row execute function public.set_updated_at();

alter table public.room_item_configs enable row level security;
alter table public.offline_event_configs enable row level security;
alter table public.moment_configs enable row level security;
alter table public.user_moment_records enable row level security;
alter table public.offline_event_history enable row level security;
alter table public.moment_assets enable row level security;
alter table public.moment_generation_tasks enable row level security;
alter table public.pending_moment_events enable row level security;

drop policy if exists "Enabled room item configs are readable" on public.room_item_configs;
create policy "Enabled room item configs are readable"
on public.room_item_configs for select
using (enabled = true and archived = false);

drop policy if exists "Enabled offline event configs are readable" on public.offline_event_configs;
create policy "Enabled offline event configs are readable"
on public.offline_event_configs for select
using (enabled = true and archived = false);

drop policy if exists "Enabled moment configs are readable" on public.moment_configs;
create policy "Enabled moment configs are readable"
on public.moment_configs for select
using (enabled = true and archived = false);

drop policy if exists "Users can manage own moment records" on public.user_moment_records;
create policy "Users can manage own moment records"
on public.user_moment_records for all
using (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = user_moment_records.pet_id
      and users.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = user_moment_records.pet_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can manage own offline event history" on public.offline_event_history;
create policy "Users can manage own offline event history"
on public.offline_event_history for all
using (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = offline_event_history.pet_id
      and users.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = offline_event_history.pet_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can read own moment assets" on public.moment_assets;
create policy "Users can read own moment assets"
on public.moment_assets for select
using (
  pet_id is null
  or exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = moment_assets.pet_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can manage own moment generation tasks" on public.moment_generation_tasks;
create policy "Users can manage own moment generation tasks"
on public.moment_generation_tasks for all
using (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = moment_generation_tasks.pet_id
      and users.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = moment_generation_tasks.pet_id
      and users.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can manage own pending moment events" on public.pending_moment_events;
create policy "Users can manage own pending moment events"
on public.pending_moment_events for all
using (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = pending_moment_events.pet_id
      and users.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.pets
    join public.users on users.id = pets.user_id
    where pets.id = pending_moment_events.pet_id
      and users.auth_user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('pet-moments', 'pet-moments', true, 10485760, array['image/png','image/jpeg','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Pet moment assets are public" on storage.objects;
create policy "Pet moment assets are public"
on storage.objects for select
using (bucket_id = 'pet-moments');

insert into public.room_item_configs (
  item_id, item_name, item_type, pet_type, default_room_asset_url, description,
  unlock_affinity_level, default_unlocked, display_order, enabled, archived
) values
  ('food_bowl', 'Food Bowl', 'basic', 'all', 'assets/room_items/food_bowl.png', 'A little bowl that makes quiet snack checks more likely.', 1, true, 10, true, false),
  ('soft_blanket', 'Soft Blanket', 'comfort', 'all', 'assets/room_items/soft_blanket.png', 'A warm blanket for naps, dreams, and sleepy returns.', 1, true, 20, true, false),
  ('toy_ball', 'Toy Ball', 'toy', 'all', 'assets/room_items/toy_ball.png', 'A bouncy toy for tiny chases and room adventures.', 1, true, 30, true, false),
  ('cat_box', 'Cat Box', 'toy', 'cat', 'assets/room_items/cat_box.png', 'A perfect little hideout for curious cats.', 3, false, 40, true, false),
  ('window_cushion', 'Window Cushion', 'scene', 'all', 'assets/room_items/window_cushion.png', 'A sunny perch for window naps and quiet watching.', 4, false, 50, true, false)
on conflict (item_id) do update set
  item_name = excluded.item_name,
  item_type = excluded.item_type,
  pet_type = excluded.pet_type,
  default_room_asset_url = excluded.default_room_asset_url,
  description = excluded.description,
  unlock_affinity_level = excluded.unlock_affinity_level,
  default_unlocked = excluded.default_unlocked,
  display_order = excluded.display_order,
  enabled = excluded.enabled,
  archived = excluded.archived;

insert into public.offline_event_configs (
  event_id, event_name, event_type, pet_type, personality_tags, required_item,
  related_items, item_weight_bonus, time_window, preferred_time_window,
  offline_min_minutes, mood_min, mood_max, hunger_min, hunger_max,
  affinity_min_level, base_weight, reward_mood, reward_hunger,
  reward_affinity, can_unlock_moment, moment_id, once_per_pet,
  title_template, body_template, image_key, enabled, archived
) values
  ('blanket_nap','Blanket Nap','sleep','all',array['Lazy','Quiet','Sweet'],'soft_blanket',array['soft_blanket'],16,array['all'],array['night','afternoon'],120,null,null,null,null,1,60,3,0,1,true,'blanket_nap',false,'A Blanket Nap','{pet_name} curled up on the soft blanket and saved the warmest corner for later.','blanket_nap',true,false),
  ('window_nap','Window Nap','window','all',array['Quiet','Gentle'],null,array['window_cushion'],18,array['afternoon','evening'],array['afternoon'],120,null,null,null,null,1,44,3,0,1,true,'window_nap',false,'Window Nap','{pet_name} watched the room get softer by the window, then dozed in the light.','window_nap',true,false),
  ('door_waiting','Door Waiting','wait','all',array['Affectionate','Shy'],null,array[]::text[],0,array['all'],array['evening'],240,null,null,null,null,1,42,2,0,1,true,'door_waiting',false,'By the Door','{pet_name} spent a quiet minute near the door, then found something cozy to do.','door_waiting',true,false),
  ('pillow_curl','Pillow Curl','sleep','all',array['Lazy','Quiet'],null,array['soft_blanket'],14,array['night'],array['night'],120,null,null,null,null,1,50,3,0,0,true,'pillow_curl',false,'A Sleepy Curl','At night, {pet_name} tucked into a small circle and breathed in tiny sleepy beats.','pillow_curl',true,false),
  ('tiny_dream','Tiny Dream','dream','all',array['Sweet','Curious'],null,array['soft_blanket'],16,array['all'],array['night'],180,70,null,null,null,1,36,4,0,1,true,'tiny_dream',false,'Tiny Dream','{pet_name} had a tiny dream and woke up looking like the room had told a secret.','tiny_dream',true,false),
  ('food_bowl_watch','Bowl Watching','food','all',array['Foodie'],null,array['food_bowl'],18,array['all'],array['morning','evening'],120,null,null,null,49,1,56,1,2,0,false,null,false,'Bowl Check','{pet_name} checked the food bowl, then waited patiently for the next meal.','food_bowl_watch',true,false),
  ('after_meal_nap','After Meal Nap','sleep','all',array['Foodie','Lazy'],null,array['food_bowl','soft_blanket'],10,array['all'],array['afternoon'],120,null,null,80,null,1,38,3,0,0,false,null,false,'After-Meal Nap','With a full little belly, {pet_name} took a peaceful nap nearby.','after_meal_nap',true,false),
  ('quiet_corner','Quiet Corner','mood','all',array['Quiet','Shy'],null,array[]::text[],0,array['all'],array['evening','night'],180,null,59,null,null,1,48,3,0,0,false,null,false,'Quiet Corner','{pet_name} picked a quiet corner and settled there until the room felt calmer.','quiet_corner',true,false),
  ('happy_roll','Happy Roll','mood','dog',array['Playful','Affectionate'],null,array['toy_ball'],12,array['all'],array['morning','afternoon'],120,80,null,null,null,1,44,4,0,1,true,'happy_roll',false,'Happy Roll','{pet_name} rolled across the rug in a very serious display of joy.','happy_roll',true,false),
  ('toy_chase','Toy Chase','play','dog',array['Playful'],'toy_ball',array['toy_ball'],22,array['all'],array['morning','afternoon'],120,null,null,null,null,1,54,5,0,1,true,'toy_chase',false,'Toy Chase','{pet_name} chased the toy ball in three proud circles, then guarded it like treasure.','toy_chase',true,false),
  ('ball_under_bed','Ball Under Bed','object','dog',array['Playful','Curious'],'toy_ball',array['toy_ball'],18,array['all'],array['afternoon'],180,null,null,null,null,1,38,3,0,0,false,null,false,'Under the Bed','{pet_name} nudged the toy ball under the bed and looked very pleased with the puzzle.','ball_under_bed',true,false),
  ('welcome_wiggle','Welcome Wiggle','mood','dog',array['Affectionate','Playful'],null,array[]::text[],0,array['all'],array['evening'],120,null,null,null,null,1,46,4,0,0,false,null,false,'Welcome Wiggle','{pet_name} did a little welcome wiggle before remembering to act composed.','welcome_wiggle',true,false),
  ('box_hideout','Box Hideout','object','cat',array['Curious','Shy','Sassy'],'cat_box',array['cat_box'],24,array['all'],array['afternoon','evening'],120,null,null,null,null,3,52,4,0,1,true,'box_hideout',false,'Box Hideout','{pet_name} discovered the box and became almost entirely invisible, except for two bright eyes.','box_hideout',true,false),
  ('tail_peek','Tail Peek','object','cat',array['Sassy','Shy'],'cat_box',array['cat_box'],20,array['all'],array['evening'],180,null,null,null,null,3,42,3,0,1,true,'tail_peek',false,'Tail Peek','Only {pet_name}''s tail peeked out for a while. The rest was classified box business.','tail_peek',true,false),
  ('sunbeam_stretch','Sunbeam Stretch','window','cat',array['Lazy','Gentle'],null,array['window_cushion'],20,array['morning','afternoon'],array['morning'],120,null,null,null,null,1,50,4,0,1,true,'sunbeam_stretch',false,'Sunbeam Stretch','{pet_name} found a sunbeam and stretched until the whole room looked warmer.','sunbeam_stretch',true,false),
  ('goodnight_purr','Goodnight Purr','sleep','cat',array['Affectionate','Quiet'],null,array['soft_blanket'],10,array['night'],array['night'],120,null,null,null,null,1,46,3,0,0,false,null,false,'Goodnight Purr','{pet_name} spent the quiet night purring softly and keeping the room company.','goodnight_purr',true,false),
  ('curtain_watch','Curtain Watch','window','cat',array['Curious','Cool'],null,array['window_cushion'],18,array['all'],array['morning','evening'],120,null,null,null,null,1,42,3,0,1,true,'curtain_watch',false,'Curtain Watch','{pet_name} sat by the curtain and observed important room mysteries.','curtain_watch',true,false),
  ('tiny_troublemaker','Tiny Troublemaker','play','all',array['Playful','Curious'],null,array['toy_ball'],18,array['all'],array['afternoon'],180,null,null,null,null,1,38,4,0,1,true,'tiny_troublemaker',false,'Tiny Troublemaker','{pet_name} rearranged one tiny thing and looked extremely innocent afterward.','tiny_troublemaker',true,false),
  ('missed_you','Missed You','wait','all',array['Affectionate','Sweet'],null,array[]::text[],0,array['all'],array['evening','night'],360,null,null,null,null,1,42,2,0,0,false,null,false,'A Quiet Wait','{pet_name} kept the room company and perked up when home felt close again.','missed_you',true,false),
  ('first_little_memory','First Little Memory','special','all',array[]::text[],null,array[]::text[],0,array['all'],array['all'],120,null,null,null,null,1,26,2,0,1,true,'first_little_memory',true,'First Little Memory','A small quiet moment with {pet_name} turned into something worth keeping.','first_little_memory',true,false)
on conflict (event_id) do update set
  event_name = excluded.event_name,
  event_type = excluded.event_type,
  pet_type = excluded.pet_type,
  personality_tags = excluded.personality_tags,
  required_item = excluded.required_item,
  related_items = excluded.related_items,
  item_weight_bonus = excluded.item_weight_bonus,
  time_window = excluded.time_window,
  preferred_time_window = excluded.preferred_time_window,
  offline_min_minutes = excluded.offline_min_minutes,
  mood_min = excluded.mood_min,
  mood_max = excluded.mood_max,
  hunger_min = excluded.hunger_min,
  hunger_max = excluded.hunger_max,
  affinity_min_level = excluded.affinity_min_level,
  base_weight = excluded.base_weight,
  reward_mood = excluded.reward_mood,
  reward_hunger = excluded.reward_hunger,
  reward_affinity = excluded.reward_affinity,
  can_unlock_moment = excluded.can_unlock_moment,
  moment_id = excluded.moment_id,
  once_per_pet = excluded.once_per_pet,
  title_template = excluded.title_template,
  body_template = excluded.body_template,
  image_key = excluded.image_key,
  enabled = excluded.enabled,
  archived = excluded.archived;

insert into public.moment_configs (
  moment_id, title, moment_type, diary_template, pet_type,
  source_type, display_order, enabled, archived
) values
  ('blanket_nap','Blanket Nap','home','{pet_name} chose the soft blanket today. It looked like a tiny promise to rest well.','all','offline_event',10,true,false),
  ('window_nap','Window Nap','home','The window light found {pet_name}, and {pet_name} let the afternoon become a nap.','all','offline_event',20,true,false),
  ('door_waiting','By the Door','home','{pet_name} waited by the door for a moment, then carried on with a brave little day.','all','offline_event',30,true,false),
  ('pillow_curl','Sleepy Curl','home','Tonight, {pet_name} curled up so neatly that the room seemed to whisper goodnight.','all','offline_event',40,true,false),
  ('tiny_dream','Tiny Dream','dream','{pet_name} woke from a tiny dream with a look that said the dream was kind.','all','offline_event',50,true,false),
  ('happy_roll','Happy Roll','home','{pet_name} rolled around with such delight that the floor briefly became a playground.','dog','offline_event',60,true,false),
  ('toy_chase','Toy Chase','home','{pet_name} chased the toy ball, won a private race, and looked very proud.','dog','offline_event',70,true,false),
  ('box_hideout','Box Hideout','home','{pet_name} found the cat box and became a small expert in hiding beautifully.','cat','offline_event',80,true,false),
  ('tail_peek','Tail Peek','home','For a while, only {pet_name}''s tail was visible. It was enough to make the room smile.','cat','offline_event',90,true,false),
  ('sunbeam_stretch','Sunbeam Stretch','home','{pet_name} stretched in the sunbeam and made the whole room feel slower.','cat','offline_event',100,true,false),
  ('curtain_watch','Curtain Watch','home','{pet_name} watched the curtain as if it might reveal a secret at any second.','cat','offline_event',110,true,false),
  ('tiny_troublemaker','Tiny Troublemaker','home','{pet_name} caused one harmless little mystery and looked impossible to accuse.','all','offline_event',120,true,false),
  ('first_little_memory','First Little Memory','special','This was the first small memory {pet_name} made at home. Small, warm, and worth keeping.','all','offline_event',130,true,false)
on conflict (moment_id) do update set
  title = excluded.title,
  moment_type = excluded.moment_type,
  diary_template = excluded.diary_template,
  pet_type = excluded.pet_type,
  source_type = excluded.source_type,
  display_order = excluded.display_order,
  enabled = excluded.enabled,
  archived = excluded.archived;
