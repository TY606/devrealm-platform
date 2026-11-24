-- =====================================================================
-- DevRealm 游戏开发者服务平台 · Supabase 数据库结构
-- 目标数据库：Postgres（Supabase 项目 SQL Editor 直接执行）
-- 说明：当前前端为示例数据原型，本脚本用于后续接入真实后端时建表。
-- =====================================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- 1. 工作室成员（关联 Supabase Auth 用户）
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text not null,
  email       text not null unique,
  role        text not null default 'dev',        -- admin / dev
  status      text not null default '在线',         -- 在线 / 忙碌 / 离线
  projects    integer not null default 0,
  avatar      text,                                 -- 头像首字母或图片 URL
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. 已接入游戏
-- ---------------------------------------------------------------------
create table if not exists public.games (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  studio      text not null,
  genre       jsonb not null default '[]'::jsonb,   -- ["RPG","探索"]
  score       integer not null default 0,
  downloads   text not null default '0',
  cover_url   text,
  description text,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. 社区帖子
-- ---------------------------------------------------------------------
create table if not exists public.posts (
  id          uuid primary key default uuid_generate_v4(),
  author_id   uuid references public.profiles (id) on delete set null,
  title       text not null,
  body        text,
  category    text,
  tags        jsonb not null default '[]'::jsonb,
  likes       integer not null default 0,
  replies     integer not null default 0,
  views       text not null default '0',
  cover_url   text,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. 资源库（插件 / SDK / 美术 / 音效 / 工具链）
-- ---------------------------------------------------------------------
create table if not exists public.resources (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  type        text not null,                         -- 工具链 / 美术素材 / 插件 / SDK / 音效
  version     text not null,
  description text,
  size        text,
  downloads   integer not null default 0,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 5. 第三方渠道接入
-- ---------------------------------------------------------------------
create table if not exists public.channels (
  id          uuid primary key default uuid_generate_v4(),
  provider    text not null,                         -- steam / discord / itch
  name        text not null,
  key_masked  text,
  enabled     boolean not null default false,
  last_sync   timestamptz,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 6. 监控日志
-- ---------------------------------------------------------------------
create table if not exists public.logs (
  id          bigserial primary key,
  ts          timestamptz not null default now(),
  level       text not null default 'INFO',         -- INFO / WARN / ERROR
  message     text not null,
  actor       text,
  cost_ms     integer
);

-- ---------------------------------------------------------------------
-- 索引
-- ---------------------------------------------------------------------
create index if not exists idx_posts_author   on public.posts (author_id);
create index if not exists idx_posts_created   on public.posts (created_at desc);
create index if not exists idx_logs_ts         on public.logs (ts desc);
create index if not exists idx_games_score    on public.games (score desc);

-- =====================================================================
-- 行级安全（RLS）预留
-- 说明：下面先开启 RLS，并给出可读策略示例；正式上线前按角色收紧写权限。
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.games    enable row level security;
alter table public.posts    enable row level security;
alter table public.resources enable row level security;
alter table public.channels enable row level security;
alter table public.logs     enable row level security;

-- 示例：已登录用户可读公开内容（写策略后续按 admin/dev 角色补充）
create policy "profiles: authenticated read" on public.profiles
  for select to authenticated using (true);
create policy "games: public read" on public.games
  for select using (true);
create policy "posts: public read" on public.posts
  for select using (true);
create policy "resources: public read" on public.resources
  for select using (true);
