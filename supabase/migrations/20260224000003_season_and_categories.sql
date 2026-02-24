-- Migration 003: 季节字段 + 扩展分类（手表/帽子/首饰/包包）

-- 1. 在 clothing_items 加 season 字段
alter table public.clothing_items
  add column if not exists season text
    check (season in ('spring','summer','autumn','winter','all'))
    default 'all';

-- 2. 扩展 clothing_items category 约束，支持 watch/hat/jewelry/bag
alter table public.clothing_items
  drop constraint if exists clothing_items_category_check;

alter table public.clothing_items
  add constraint clothing_items_category_check
    check (category in (
      'tops','bottoms','shoes','outerwear','accessories',
      'watch','hat','jewelry','bag'
    ));

-- 3. 在 outfits 表也加 season 字段，方便按季节查询历史穿搭
alter table public.outfits
  add column if not exists season text
    check (season in ('spring','summer','autumn','winter','all'));

-- 4. 索引：按 user_id + season 快速筛选
create index if not exists idx_clothing_items_user_season
  on public.clothing_items(user_id, season);

create index if not exists idx_clothing_items_user_category
  on public.clothing_items(user_id, category);
