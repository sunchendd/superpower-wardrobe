-- Migration 004: 重构数据库 schema — 参考氢气衣橱全功能设计
-- 新增表: user_profiles, categories, outfit_items, outfit_diary,
--         purchase_recommendations, travel_plans, travel_plan_outfits
-- 重构表: clothing_items (新增字段), outfits (新增字段), daily_recommendations (新增字段)

-- ============================================================
-- 1. user_profiles — 用户扩展资料
-- ============================================================
create table public.user_profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  avatar_url text,
  phone text,
  body_info jsonb default '{}',           -- {"height": 175, "weight": 65, "body_type": "average"}
  style_preferences text[] default '{}',  -- ['casual', 'streetwear', 'minimal']
  location text,                          -- 常驻城市
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.user_profiles enable row level security;
create policy "Users manage own profile" on public.user_profiles
  for all using (auth.uid() = id);

-- 自动创建 profile（Supabase Auth trigger）
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id)
  values (new.id);
  return new;
end;
$$ language plpgsql security definer;

-- 如果 trigger 已存在则先删除
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 2. categories — 衣物品类（层级结构）
-- ============================================================
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon text,
  sort_order int default 0,
  parent_id uuid references public.categories,
  created_at timestamptz default now()
);
alter table public.categories enable row level security;
create policy "Everyone reads categories" on public.categories
  for select using (true);

-- 预置品类数据
insert into public.categories (id, name, icon, sort_order) values
  ('a0000000-0000-0000-0000-000000000001', '上衣', 'tshirt', 1),
  ('a0000000-0000-0000-0000-000000000002', '下装', 'pants', 2),
  ('a0000000-0000-0000-0000-000000000003', '外套', 'jacket', 3),
  ('a0000000-0000-0000-0000-000000000004', '鞋子', 'shoe', 4),
  ('a0000000-0000-0000-0000-000000000005', '配饰', 'accessory', 5);

-- 子分类
insert into public.categories (name, icon, sort_order, parent_id) values
  -- 上衣子分类
  ('T恤', 'tshirt', 1, 'a0000000-0000-0000-0000-000000000001'),
  ('衬衫', 'shirt', 2, 'a0000000-0000-0000-0000-000000000001'),
  ('卫衣', 'hoodie', 3, 'a0000000-0000-0000-0000-000000000001'),
  ('毛衣', 'sweater', 4, 'a0000000-0000-0000-0000-000000000001'),
  ('背心', 'vest', 5, 'a0000000-0000-0000-0000-000000000001'),
  ('POLO衫', 'polo', 6, 'a0000000-0000-0000-0000-000000000001'),
  -- 下装子分类
  ('长裤', 'trousers', 1, 'a0000000-0000-0000-0000-000000000002'),
  ('短裤', 'shorts', 2, 'a0000000-0000-0000-0000-000000000002'),
  ('裙子', 'skirt', 3, 'a0000000-0000-0000-0000-000000000002'),
  ('牛仔裤', 'jeans', 4, 'a0000000-0000-0000-0000-000000000002'),
  -- 外套子分类
  ('夹克', 'jacket', 1, 'a0000000-0000-0000-0000-000000000003'),
  ('大衣', 'coat', 2, 'a0000000-0000-0000-0000-000000000003'),
  ('羽绒服', 'down_jacket', 3, 'a0000000-0000-0000-0000-000000000003'),
  ('风衣', 'trench', 4, 'a0000000-0000-0000-0000-000000000003'),
  ('西装外套', 'blazer', 5, 'a0000000-0000-0000-0000-000000000003'),
  -- 鞋子子分类
  ('运动鞋', 'sneaker', 1, 'a0000000-0000-0000-0000-000000000004'),
  ('皮鞋', 'leather_shoe', 2, 'a0000000-0000-0000-0000-000000000004'),
  ('靴子', 'boot', 3, 'a0000000-0000-0000-0000-000000000004'),
  ('凉鞋', 'sandal', 4, 'a0000000-0000-0000-0000-000000000004'),
  ('拖鞋', 'slipper', 5, 'a0000000-0000-0000-0000-000000000004'),
  -- 配饰子分类
  ('手表', 'watch', 1, 'a0000000-0000-0000-0000-000000000005'),
  ('帽子', 'hat', 2, 'a0000000-0000-0000-0000-000000000005'),
  ('首饰', 'jewelry', 3, 'a0000000-0000-0000-0000-000000000005'),
  ('包', 'bag', 4, 'a0000000-0000-0000-0000-000000000005'),
  ('围巾', 'scarf', 5, 'a0000000-0000-0000-0000-000000000005'),
  ('眼镜', 'glasses', 6, 'a0000000-0000-0000-0000-000000000005'),
  ('腰带', 'belt', 7, 'a0000000-0000-0000-0000-000000000005');

-- ============================================================
-- 3. 扩展 clothing_items — 新增品牌/价格/购买信息/状态
-- ============================================================
alter table public.clothing_items
  add column if not exists category_id uuid references public.categories,
  add column if not exists brand text,
  add column if not exists style_tags text[] default '{}',
  add column if not exists purchase_price numeric,
  add column if not exists purchase_date date,
  add column if not exists purchase_url text,
  add column if not exists wear_count int default 0,
  add column if not exists status text default 'active'
    check (status in ('active', 'idle', 'retired'));

create index if not exists idx_clothing_items_status
  on public.clothing_items(user_id, status);

-- ============================================================
-- 4. 重构 outfits — 添加 name/rating，准备关联表迁移
-- ============================================================
alter table public.outfits
  add column if not exists name text,
  add column if not exists rating int check (rating between 1 and 5);

-- ============================================================
-- 5. outfit_items — 穿搭-单品多对多关联（替代 item_ids 数组）
-- ============================================================
create table public.outfit_items (
  outfit_id uuid references public.outfits on delete cascade,
  clothing_item_id uuid references public.clothing_items on delete cascade,
  primary key (outfit_id, clothing_item_id)
);
alter table public.outfit_items enable row level security;
create policy "Users manage own outfit items" on public.outfit_items
  for all using (
    exists (
      select 1 from public.outfits
      where id = outfit_items.outfit_id and user_id = auth.uid()
    )
  );

-- ============================================================
-- 6. outfit_diary — 穿搭日记/今日穿搭
-- ============================================================
create table public.outfit_diary (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  outfit_id uuid references public.outfits,
  photo_url text,
  note text,
  weather_data jsonb,
  mood text check (mood in ('great', 'good', 'okay', 'bad')),
  shared_at timestamptz,
  created_at timestamptz default now()
);
alter table public.outfit_diary enable row level security;
create policy "Users manage own diary" on public.outfit_diary
  for all using (auth.uid() = user_id);

create index if not exists idx_outfit_diary_user_date
  on public.outfit_diary(user_id, date);

-- ============================================================
-- 7. 扩展 daily_recommendations — 推荐理由 + 反馈评分
-- ============================================================
alter table public.daily_recommendations
  add column if not exists reason_text text,
  add column if not exists feedback_score int check (feedback_score between 1 and 5);

-- ============================================================
-- 8. purchase_recommendations — 购买推荐
-- ============================================================
create table public.purchase_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  category_id uuid references public.categories,
  reason text not null,              -- 'wardrobe_gap' | 'seasonal' | 'style_match' | 'trending'
  description text,                  -- 人类可读推荐理由
  style_tags text[] default '{}',
  season text check (season in ('spring', 'summer', 'autumn', 'winter', 'all')),
  priority int default 0,
  status text default 'new'
    check (status in ('new', 'viewed', 'purchased', 'dismissed')),
  created_at timestamptz default now()
);
alter table public.purchase_recommendations enable row level security;
create policy "Users manage own purchase recs" on public.purchase_recommendations
  for all using (auth.uid() = user_id);

create index if not exists idx_purchase_recs_user_status
  on public.purchase_recommendations(user_id, status);

-- ============================================================
-- 9. travel_plans — 旅行穿搭计划
-- ============================================================
create table public.travel_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  title text not null,
  destination text,
  start_date date not null,
  end_date date not null,
  created_at timestamptz default now()
);
alter table public.travel_plans enable row level security;
create policy "Users manage own travel plans" on public.travel_plans
  for all using (auth.uid() = user_id);

-- ============================================================
-- 10. travel_plan_outfits — 旅行计划每日穿搭
-- ============================================================
create table public.travel_plan_outfits (
  id uuid primary key default gen_random_uuid(),
  travel_plan_id uuid references public.travel_plans on delete cascade not null,
  date date not null,
  outfit_id uuid references public.outfits,
  note text,
  unique (travel_plan_id, date)
);
alter table public.travel_plan_outfits enable row level security;
create policy "Users manage own travel outfits" on public.travel_plan_outfits
  for all using (
    exists (
      select 1 from public.travel_plans
      where id = travel_plan_outfits.travel_plan_id and user_id = auth.uid()
    )
  );

-- ============================================================
-- 11. updated_at 自动更新触发器
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_user_profiles_updated_at
  before update on public.user_profiles
  for each row execute procedure public.set_updated_at();
