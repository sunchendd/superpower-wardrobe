-- Migration 002: schema improvements + expand presets

-- 1. Make image_url nullable (不是每件衣服都有图片)
alter table public.clothing_items
  alter column image_url drop not null;

-- 2. Add a demo-user RLS policy (allows inserts with demo UUID when using anon key + service)
-- We also add a policy so demo user can see their own data
create policy "Demo user can manage items" on public.clothing_items
  for all using (user_id = '00000000-0000-0000-0000-000000000001'::uuid)
  with check (user_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- 3. Add season column to preset_outfits
alter table public.preset_outfits
  add column if not exists season text check (season in ('spring','summer','autumn','winter','all'));

-- 4. Add detail column for richer descriptions
alter table public.preset_outfits
  add column if not exists detail text;

-- 5. Clear old presets and insert comprehensive ones
truncate table public.preset_outfits restart identity cascade;

insert into public.preset_outfits (name, categories, occasion, weather_tags, season, detail) values

-- ====== 春季 Spring (10-20°C, mild) ======
('白色牛津纺衬衫 + 卡其棉质休闲裤 + 白色小白鞋',
 array['tops','bottoms','shoes'], 'casual', array['mild'], 'spring',
 '清爽春日基本款，百搭耐看'),

('薄款针织毛衣 + 深蓝牛仔裤 + 白色运动鞋 + 皮带手表',
 array['tops','bottoms','shoes','accessories'], 'casual', array['mild'], 'spring',
 '针织毛衣显层次，手表提升质感'),

('条纹海魂衫 + 白色休闲裤 + 帆布鞋',
 array['tops','bottoms','shoes'], 'casual', array['mild'], 'spring',
 '法式海军风，轻松有型'),

('浅灰西装外套 + 黑色西装裤 + 白衬衫 + 黑色德比鞋',
 array['outerwear','bottoms','tops','shoes'], 'work', array['mild'], 'spring',
 '春季商务通勤，灰色套装优雅干练'),

('白色polo衫 + 藏青休闲裤 + 乐福鞋 + 精钢表',
 array['tops','bottoms','shoes','accessories'], 'work', array['mild'], 'spring',
 '商务休闲两用，polo+乐福永不出错'),

('运动长袖T + 运动长裤 + 跑步鞋',
 array['tops','bottoms','shoes'], 'sport', array['mild'], 'spring',
 '春季晨跑标配，透气舒适'),

('薄风衣 + 圆领T恤 + 修身牛仔裤 + 切尔西靴',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['mild','cool'], 'spring',
 '早晚温差大的春日，风衣是最佳外套'),

-- ====== 夏季 Summer (25°C+, warm/hot) ======
('白色纯棉T恤 + 深色牛仔短裤 + 白色板鞋',
 array['tops','bottoms','shoes'], 'casual', array['warm','hot'], 'summer',
 '夏日最基本也最经典的搭配'),

('POLO衫 + 浅色休闲短裤 + 编织皮带凉鞋',
 array['tops','bottoms','shoes'], 'casual', array['warm','hot'], 'summer',
 '休闲度假感，轻松又有品味'),

('亚麻短袖衬衫 + 白色棉麻短裤 + 帆布帆布鞋',
 array['tops','bottoms','shoes'], 'casual', array['warm','hot'], 'summer',
 '亚麻材质透气，夏日首选'),

('白色短袖衬衫 + 浅灰西裤 + 棕色皮鞋 + 石英腕表',
 array['tops','bottoms','shoes','accessories'], 'work', array['warm'], 'summer',
 '夏季商务，浅色系降低体感温度'),

('速干运动T恤 + 运动短裤 + 专业跑鞋',
 array['tops','bottoms','shoes'], 'sport', array['warm','hot'], 'summer',
 '夏季运动必备，速干材质排汗凉爽'),

('条纹短袖polo + 卡其短裤 + 棕色沙滩凉拖 + 编织手表',
 array['tops','bottoms','shoes','accessories'], 'casual', array['hot'], 'summer',
 '海边度假风，编织手表增添异域感'),

('印花短袖T恤 + 黑色修身短裤 + 白色运动鞋',
 array['tops','bottoms','shoes'], 'casual', array['warm','hot'], 'summer',
 '图案T恤是夏日造型亮点'),

-- ====== 秋季 Autumn (10-20°C, cool/mild) ======
('格子法兰绒衬衫 + 深蓝牛仔裤 + 棕色皮质切尔西靴',
 array['tops','bottoms','shoes'], 'casual', array['cool','mild'], 'autumn',
 '秋日经典格子，皮靴提升层次'),

('焦糖色毛衣 + 深灰修身西裤 + 棕色德比鞋 + 精钢机械表',
 array['tops','bottoms','shoes','accessories'], 'work', array['cool'], 'autumn',
 '秋季暖色调搭配，机械表彰显品位'),

('卡其色长款风衣 + 黑色高领毛衣 + 黑色窄脚裤 + 切尔西靴',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['cool','cold'], 'autumn',
 '秋冬过渡款，风衣是秋季最佳外套'),

('牛仔外套 + 白色基础T + 黑色直筒裤 + 白球鞋',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['mild','cool'], 'autumn',
 '美式校园风，牛仔外套百搭'),

('橄榄绿夹克 + 灰色圆领卫衣 + 黑色工装裤 + 马丁靴',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['cool'], 'autumn',
 '工装风格高级，马丁靴耐看实用'),

('深棕色针织开衫 + 白衬衫 + 卡其裤 + 乐福鞋 + 皮革手表带腕表',
 array['outerwear','tops','bottoms','shoes','accessories'], 'work', array['cool'], 'autumn',
 '学院风通勤，皮表带腕表优雅'),

('运动连帽卫衣 + 运动长裤 + 复古跑鞋',
 array['tops','bottoms','shoes'], 'sport', array['cool','mild'], 'autumn',
 '秋季户外运动，连帽卫衣保暖透气'),

('深色格纹西装 + 白衬衫 + 深灰西裤 + 黑色牛津鞋',
 array['outerwear','tops','bottoms','shoes'], 'formal', array['mild','cool'], 'autumn',
 '秋季正式场合首选，格纹西装有个性'),

-- ====== 冬季 Winter (<10°C, cold) ======
('驼色羊毛大衣 + 黑色高领毛衣 + 深灰剪裁裤 + 棕色切尔西靴',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['cold'], 'winter',
 '冬日高级感标配，羊毛大衣版型要好'),

('黑色羽绒服 + 灰色连帽衫 + 黑色修身裤 + 白色运动鞋',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['cold'], 'winter',
 '都市通勤冬季实用款'),

('深蓝色航海夹克 + 粗棱纹毛衣 + 黑色牛仔裤 + 棕色皮靴',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['cold'], 'winter',
 '英伦风冬日造型，粗纹毛衣质感强'),

('黑色大衣 + 黑色西装 + 白衬衫 + 黑色西裤 + 黑色皮鞋 + 银色腕表',
 array['outerwear','tops','bottoms','shoes','accessories'], 'formal', array['cold'], 'winter',
 '全黑正装，银表点亮整体'),

('羊绒双面大衣 + 驼色针织毛衣 + 深棕皮裤 + 切尔西靴 + 皮革腕表',
 array['outerwear','tops','bottoms','shoes','accessories'], 'casual', array['cold'], 'winter',
 '冬日高端休闲，全套暖色系协调'),

('厚款羽绒背心 + 格子法兰绒衬衫 + 灰色卫衣 + 卡其工装裤 + 马丁靴',
 array['outerwear','tops','bottoms','shoes'], 'casual', array['cold'], 'winter',
 '层叠穿搭，既保暖又有层次感'),

('商务羊毛西装外套 + 高领羊绒衫 + 深灰西裤 + 黑色德比鞋 + 机械腕表',
 array['outerwear','tops','bottoms','shoes','accessories'], 'work', array['cold'], 'winter',
 '冬季商务精英感，高领毛衫替代衬衫+领带'),

('滑雪夹克 + 速干内胆 + 运动长裤 + 高帮雪地靴',
 array['outerwear','tops','bottoms','shoes'], 'sport', array['cold'], 'winter',
 '冬季户外运动专属'),

-- ====== 全季通用 All-season ======
('黑色西装三件套 + 白衬衫 + 黑色皮鞋 + 黑色领带 + 银色腕表',
 array['outerwear','tops','bottoms','shoes','accessories'], 'formal', array['mild','cool','cold'], 'all',
 '男士正装永恒经典，适合各类正式场合'),

('深海军蓝西装外套 + 卡其裤 + 白衬衫 + 棕色乐福鞋 + 棕色皮带表',
 array['outerwear','tops','bottoms','shoes','accessories'], 'work', array['mild','cool'], 'all',
 'Business casual 标配，蓝棕色彩搭配经典'),

('全黑休闲套装：黑T+黑直筒裤+黑运动鞋',
 array['tops','bottoms','shoes'], 'casual', array['warm','mild','cool'], 'all',
 '极简全黑风，高级且百搭');
