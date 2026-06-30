alter table public.pets
  add column if not exists affinity_value integer not null default 0 check (affinity_value >= 0),
  add column if not exists affinity_level integer not null default 1 check (affinity_level between 1 and 5),
  add column if not exists last_settlement_at timestamptz not null default now(),
  add column if not exists last_daily_reset_date text not null default to_char(now(), 'YYYY-MM-DD'),
  add column if not exists feed_last_at timestamptz,
  add column if not exists caress_last_at timestamptz,
  add column if not exists feed_effective_count_today integer not null default 0 check (feed_effective_count_today >= 0),
  add column if not exists caress_effective_count_today integer not null default 0 check (caress_effective_count_today >= 0),
  add column if not exists chat_mood_gain_today integer not null default 0 check (chat_mood_gain_today >= 0),
  add column if not exists valid_chat_count_today integer not null default 0 check (valid_chat_count_today >= 0),
  add column if not exists affinity_gain_today integer not null default 0 check (affinity_gain_today >= 0),
  add column if not exists return_tip_show_count_today integer not null default 0 check (return_tip_show_count_today >= 0),
  add column if not exists daily_first_feed_done boolean not null default false,
  add column if not exists daily_first_caress_done boolean not null default false,
  add column if not exists daily_chat_affinity_done boolean not null default false,
  add column if not exists daily_first_return_done boolean not null default false;

update public.pets
set
  affinity_level = case
    when affinity_value >= 30 then 5
    when affinity_value >= 14 then 4
    when affinity_value >= 7 then 3
    when affinity_value >= 3 then 2
    else 1
  end,
  last_settlement_at = coalesce(last_active_at, created_at, last_settlement_at, now()),
  last_daily_reset_date = coalesce(last_daily_reset_date, to_char(now(), 'YYYY-MM-DD'));
