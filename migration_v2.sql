-- =====================================================================
-- DevRealm · 第二轮迁移：协作表 + 管理后台权限 + 注册自动建档
-- 前置：已执行 schema.sql / seed.sql。在 Supabase SQL Editor 重复执行即可。
-- 说明：anonKey 仅用于前端；本脚本必须在后台 SQL Editor（有权限）执行。
-- =====================================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- 0. 管理员判定函数（security definer，避免 RLS 递归）
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists(
    select 1 from public.profiles
    where auth_id = auth.uid() and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
-- 1. 评论（帖子 / 游戏 / 资源 / 视频 / 文章通用）
-- ---------------------------------------------------------------------
create table if not exists public.comments (
  id           uuid primary key default uuid_generate_v4(),
  target_type  text not null,                 -- post / game / resource / video / article
  target_id    text not null,                 -- 帖子标题 / 游戏名 / 资源 id 等
  author_id    uuid references public.profiles(id) on delete set null,
  author_name  text not null default '',
  role         text not null default 'dev',
  body         text not null,
  created_at   timestamptz not null default now()
);
create index if not exists idx_comments_target on public.comments(target_type, target_id);

-- ---------------------------------------------------------------------
-- 2. 任务（成员协作：派任务、跟进状态）
-- ---------------------------------------------------------------------
create table if not exists public.tasks (
  id           uuid primary key default uuid_generate_v4(),
  title        text not null,
  detail       text,
  assignee_id  uuid references public.profiles(id) on delete set null,
  assignee_name text not null default '',
  creator_id   uuid references public.profiles(id) on delete set null,
  creator_name text not null default '',
  status       text not null default 'todo',  -- todo / doing / done
  priority     text not null default 'normal',-- low / normal / high
  created_at   timestamptz not null default now()
);
create index if not exists idx_tasks_assignee on public.tasks(assignee_id);

-- ---------------------------------------------------------------------
-- 3. 成员对话（按会话 channel 分组，channel 一般为对方成员名）
-- ---------------------------------------------------------------------
create table if not exists public.messages (
  id           uuid primary key default uuid_generate_v4(),
  channel      text not null,
  sender_id    uuid references public.profiles(id) on delete set null,
  sender_name  text not null default '',
  body         text not null,
  created_at   timestamptz not null default now()
);
create index if not exists idx_messages_channel on public.messages(channel);

-- ---------------------------------------------------------------------
-- 4. 资源分享（把资源分享给某位成员）
-- ---------------------------------------------------------------------
create table if not exists public.shares (
  id           uuid primary key default uuid_generate_v4(),
  resource_id  text,
  resource_name text not null default '',
  from_id      uuid references public.profiles(id) on delete set null,
  from_name    text not null default '',
  to_id        uuid references public.profiles(id) on delete set null,
  to_name      text not null default '',
  note         text,
  created_at   timestamptz not null default now()
);
create index if not exists idx_shares_to on public.shares(to_id);

-- ---------------------------------------------------------------------
-- 5. 审计日志（管理员在后台的关键操作留痕）
-- ---------------------------------------------------------------------
create table if not exists public.audit_logs (
  id           bigserial primary key,
  actor        text not null default '',
  action       text not null,
  target       text,
  detail       text,
  created_at   timestamptz not null default now()
);

-- games 补下载链接列
alter table public.games add column if not exists download_url text;

-- =====================================================================
-- 行级安全（RLS）
-- =====================================================================
alter table public.comments  enable row level security;
alter table public.tasks     enable row level security;
alter table public.messages   enable row level security;
alter table public.shares    enable row level security;
alter table public.audit_logs enable row level security;

-- 通用：公开可读
drop policy if exists "comments: public read" on public.comments;
create policy "comments: public read" on public.comments for select using (true);
drop policy if exists "tasks: public read" on public.tasks;
create policy "tasks: public read" on public.tasks for select using (true);
drop policy if exists "messages: public read" on public.messages;
create policy "messages: public read" on public.messages for select using (true);
drop policy if exists "shares: public read" on public.shares;
create policy "shares: public read" on public.shares for select using (true);
drop policy if exists "audit_logs: public read" on public.audit_logs;
create policy "audit_logs: public read" on public.audit_logs for select using (true);

-- 通用：登录用户可插入（作者为本人档案）
drop policy if exists "comments: authenticated insert" on public.comments;
create policy "comments: authenticated insert" on public.comments
  for insert to authenticated
  with check (author_id in (select id from public.profiles where auth_id = auth.uid()));
drop policy if exists "tasks: authenticated insert" on public.tasks;
create policy "tasks: authenticated insert" on public.tasks
  for insert to authenticated
  with check (creator_id in (select id from public.profiles where auth_id = auth.uid()));
drop policy if exists "messages: authenticated insert" on public.messages;
create policy "messages: authenticated insert" on public.messages
  for insert to authenticated
  with check (sender_id in (select id from public.profiles where auth_id = auth.uid()));
drop policy if exists "shares: authenticated insert" on public.shares;
create policy "shares: authenticated insert" on public.shares
  for insert to authenticated
  with check (from_id in (select id from public.profiles where auth_id = auth.uid()));
drop policy if exists "audit_logs: authenticated insert" on public.audit_logs;
create policy "audit_logs: authenticated insert" on public.audit_logs
  for insert to authenticated with check (true);

-- 通用：作者本人或管理员可更新 / 删除
drop policy if exists "comments: author or admin write" on public.comments;
create policy "comments: author or admin write" on public.comments
  for update to authenticated
  using (author_id in (select id from public.profiles where auth_id = auth.uid()) or public.is_admin())
  with check (author_id in (select id from public.profiles where auth_id = auth.uid()) or public.is_admin());
drop policy if exists "comments: author or admin delete" on public.comments;
create policy "comments: author or admin delete" on public.comments
  for delete to authenticated
  using (author_id in (select id from public.profiles where auth_id = auth.uid()) or public.is_admin());

drop policy if exists "tasks: member or admin write" on public.tasks;
create policy "tasks: member or admin write" on public.tasks
  for update to authenticated
  using (public.is_admin() or creator_id in (select id from public.profiles where auth_id = auth.uid())
         or assignee_id in (select id from public.profiles where auth_id = auth.uid()))
  with check (true);
drop policy if exists "tasks: admin delete" on public.tasks;
create policy "tasks: admin delete" on public.tasks
  for delete to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------
-- 6. 既有表的管理员写权限（内容管理后台增删改查）
-- ---------------------------------------------------------------------
-- 游戏：管理员可增删改
drop policy if exists "games: admin write" on public.games;
create policy "games: admin write" on public.games
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 资源：管理员可增删改
drop policy if exists "resources: admin write" on public.resources;
create policy "resources: admin write" on public.resources
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 成员档案：管理员可增删改；本人可改自己的基础资料
drop policy if exists "profiles: admin write" on public.profiles;
create policy "profiles: admin write" on public.profiles
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
drop policy if exists "profiles: self update" on public.profiles;
create policy "profiles: self update" on public.profiles
  for update to authenticated
  using (auth_id = auth.uid()) with check (auth_id = auth.uid());

-- 帖子：管理员可删除 / 编辑
drop policy if exists "posts: admin delete" on public.posts;
create policy "posts: admin delete" on public.posts
  for delete to authenticated using (public.is_admin());
drop policy if exists "posts: admin update" on public.posts;
create policy "posts: admin update" on public.posts
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- 渠道：管理员可增删
drop policy if exists "channels: admin write" on public.channels;
create policy "channels: admin write" on public.channels
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- =====================================================================
-- 7. 注册自动建档：新 Auth 用户注册后，自动在 profiles 建一条 dev 档案
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (auth_id, name, email, role, status, projects)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    'dev',
    '在线',
    0
  )
  on conflict (email) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
