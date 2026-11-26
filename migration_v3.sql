-- =====================================================================
-- DevRealm 三期迁移：开发工作台项目表 + 头像字段
-- 依赖：migration_v2.sql（is_admin()、profiles 表）
-- 在 Supabase SQL Editor 中顺序执行；脚本可重复执行（幂等）。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. profiles 增加头像字段（dataURL 或内置 emoji 字符）
-- ---------------------------------------------------------------------
alter table public.profiles add column if not exists avatar text;

-- ---------------------------------------------------------------------
-- 2. projects 开发工作台项目表
--    id 由前端生成（p + 时间戳），故主键用 text
-- ---------------------------------------------------------------------
create table if not exists public.projects (
  id            text primary key,
  owner_id      uuid references public.profiles(id) on delete set null,
  owner_name    text not null default '',
  name          text not null,
  template      text not null default 'tap',
  code          text,
  status        text not null default '开发中',
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. RLS：公开只读；登录可新建；本人或管理员可改、可删
-- ---------------------------------------------------------------------
alter table public.projects enable row level security;

drop policy if exists "projects: public read" on public.projects;
create policy "projects: public read" on public.projects
  for select using (true);

drop policy if exists "projects: authenticated insert" on public.projects;
create policy "projects: authenticated insert" on public.projects
  for insert to authenticated
  with check (owner_id in (select id from public.profiles where auth_id = auth.uid()));

drop policy if exists "projects: owner or admin update" on public.projects;
create policy "projects: owner or admin update" on public.projects
  for update to authenticated
  using (public.is_admin() or owner_id in (select id from public.profiles where auth_id = auth.uid()))
  with check (public.is_admin() or owner_id in (select id from public.profiles where auth_id = auth.uid()));

drop policy if exists "projects: owner or admin delete" on public.projects;
create policy "projects: owner or admin delete" on public.projects
  for delete to authenticated
  using (public.is_admin() or owner_id in (select id from public.profiles where auth_id = auth.uid()));
