-- 衣物表
create table public.clothing_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  image_url text not null,
  category text not null check (category in ('tops','bottoms','shoes','outerwear','accessories')),
  color text not null,
  tags text[] default '{}',
  name text,
  created_at timestamptz default now()
);
alter table public.clothing_items enable row level security;
create policy "Users manage own items" on public.clothing_items
  for all using (auth.uid() = user_id);

-- 穿搭组合表
create table public.outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  item_ids uuid[] default '{}',
  occasion text check (occasion in ('casual','work','sport','formal')),
  source text check (source in ('ai_generated','preset','user_created')),
  created_at timestamptz default now()
);
alter table public.outfits enable row level security;
create policy "Users manage own outfits" on public.outfits
  for all using (auth.uid() = user_id);

-- 内置 preset 套装
create table public.preset_outfits (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  categories text[] not null,
  occasion text check (occasion in ('casual','work','sport','formal')),
  weather_tags text[] default '{}'
);
alter table public.preset_outfits enable row level security;
create policy "Everyone reads presets" on public.preset_outfits
  for select using (true);

-- 每日推荐记录表
create table public.daily_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  outfit_id uuid references public.outfits,
  weather_data jsonb,
  accepted bool default false,
  unique(user_id, date)
);
alter table public.daily_recommendations enable row level security;
create policy "Users manage own recommendations" on public.daily_recommendations
  for all using (auth.uid() = user_id);
