-- =====================================================================
-- DevRealm 游戏开发者服务平台 · 示例数据导入脚本
-- 前置：先在 SQL Editor 执行 schema.sql 建好 6 张表。
-- 说明：本脚本把前端演示用的示例数据灌入对应表，便于接入后直接看到列表。
--       重复执行会先清空业务表再插入（不会删除账号）。
-- =====================================================================

-- 清理（按外键依赖逆序）
truncate table public.posts, public.logs, public.channels, public.resources, public.games, public.profiles restart identity cascade;

-- ---------------------------------------------------------------------
-- 1. 工作室成员
-- 说明：profiles.id 不绑定 auth.users，演示用固定 uuid 占位即可，无需先在 Auth 建账号。
-- ---------------------------------------------------------------------
insert into public.profiles (id, name, email, role, status, projects) values
  ('11111111-1111-1111-1111-111111111111', '陶云', 'taoyun@devrealm.dev',   'admin', '在线', 3),
  ('22222222-2222-2222-2222-222222222222', '李承宇', 'lichengyu@devrealm.dev', 'dev',   '在线', 2),
  ('33333333-3333-3333-3333-333333333333', '林晚',   'linwan@devrealm.dev',   'dev',   '忙碌', 1),
  ('44444444-4444-4444-4444-444444444444', '周屿',   'zhouyu@devrealm.dev',   'dev',   '离线', 2),
  ('55555555-5555-5555-5555-555555555555', '许清',   'xuqing@devrealm.dev',   'admin', '在线', 4);

-- ---------------------------------------------------------------------
-- 2. 已接入游戏（封面 cover_url 留空时前端回退内置封面）
-- ---------------------------------------------------------------------
insert into public.games (name, studio, genre, score, downloads) values
  ('星轨回声', 'Nebula Studio', '["RPG","探索"]',   92, '12.4k'),
  ('灰港骑士', 'Ashline',        '["动作","RPG"]',   88, '8.7k'),
  ('萤火林地', 'Softwood',       '["休闲","治愈"]',   86, '21.2k'),
  ('熔心远征', 'Cinder Team',    '["策略","射击"]',   83, '6.1k'),
  ('雾海信标', 'Tidefall',       '["探索","悬疑"]',   81, '4.8k');

-- ---------------------------------------------------------------------
-- 3. 资源库
-- ---------------------------------------------------------------------
insert into public.resources (name, type, version, description, size, downloads) values
  ('Sprite Atlas Packer',      '工具链',   '2.4.1', '把散图自动打成图集，输出 Unity / Cocos 可直接引用的描述文件。', '18 MB', 1240),
  ('Pixel Shader Library',     '美术素材', '1.8.0', '42 组可商用像素风着色器，含色板与示例场景。',                 '6 MB',  860),
  ('Dialogue Graph Kit',       '插件',     '0.9.7', '可视化剧情分支编辑，导出 JSON 供运行时读取，支持多语言。',     '3 MB',  512),
  ('Live Ops Analytics SDK',   'SDK',      '3.2.0', '埋点、留存与付费漏斗统计，兼容 Unity 与 Unreal。',             '2 MB',  2030),
  ('Retro SFX Bundle',         '音效',     '1.0.2', '8-bit 风格 120 条音效，已做归一化与去噪处理。',                 '24 MB', 740),
  ('Build Pipeline CLI',       '工具链',   '1.4.3', '一条命令完成多平台打包、版本号递增与产物上传。',               '9 MB',  398);

-- ---------------------------------------------------------------------
-- 4. 第三方渠道接入
-- ---------------------------------------------------------------------
insert into public.channels (provider, name, key_masked, enabled, last_sync) values
  ('steam',   'Steamworks',            'stm_live_9f2c••••37a1',  true,  '2026-11-20 14:22'),
  ('discord', 'Discord Rich Presence', 'dsc_oauth_8b71••••c924', true,  '2026-11-21 09:41'),
  ('itch',    'itch.io Butler',        'itch_api_5e83••••11fd',  false, '2026-11-12 17:08');

-- ---------------------------------------------------------------------
-- 5. 监控日志
-- ---------------------------------------------------------------------
insert into public.logs (ts, level, message, actor, cost_ms) values
  ('2026-11-25 09:41:02', 'INFO', 'GET /v1/assets 200 34ms',            'dev',    34),
  ('2026-11-25 09:38:47', 'WARN', 'POST /v1/assets/upload 429 限流触发', 'dev',    0),
  ('2026-11-25 09:31:15', 'INFO', 'GET /v1/integrations 200 51ms',      'admin',  51),
  ('2026-11-25 09:24:03', 'ERROR','GET /v1/health 504 对象存储超时',     'system', 0),
  ('2026-11-25 09:12:39', 'INFO', 'POST /v1/apilog 201 8ms',            'admin',  8),
  ('2026-11-25 09:02:10', 'INFO', 'HANDSHAKE Steamworks 200 42ms',       'admin',  42),
  ('2026-11-25 08:56:33', 'INFO', 'SYNC Discord Rich Presence 200 63ms','admin',  63);

-- ---------------------------------------------------------------------
-- 6. 社区帖子（author_id 按邮箱关联成员）
-- ---------------------------------------------------------------------
insert into public.posts (author_id, category, title, tags, likes, replies, views) values
  ((select id from public.profiles where email='taoyun@devrealm.dev'),
   '学术交流', '帧同步在 2D 平台跳跃里的确定性坑：浮点、随机种子和输入延迟', '["帧同步","Unity"]', 425, 12, '12.4k'),
  ((select id from public.profiles where email='lichengyu@devrealm.dev'),
   '疑难问答', 'Unity IL2CPP 出 Android 包后，Steamworks 的回调在主线程不触发', '["IL2CPP","Steamworks"]', 86, 12, '3.1k'),
  ((select id from public.profiles where email='taoyun@devrealm.dev'),
   '经验分享', '独立游戏上 Steam 之前，我踩过的 7 个发行坑（预算 0 的那种）', '["发行","Steam"]', 318, 41, '9.8k'),
  ((select id from public.profiles where email='lichengyu@devrealm.dev'),
   '疑难问答', 'Spine 骨骼动画在 URP 下描边闪烁，换材质也压不住，有稳定方案吗？', '["Spine","URP"]', 57, 9, '2.2k'),
  ((select id from public.profiles where email='taoyun@devrealm.dev'),
   '学术交流', '小团队该不该上 ECS？一个 6 个月项目的取舍复盘', '["ECS","架构"]', 194, 23, '5.7k');
