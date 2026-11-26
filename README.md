# DevRealm · 游戏开发者服务平台

面向独立游戏团队的开发者控制台原型：数据看板、游戏库、排行榜、API 调试、资源库、渠道接入、监控日志、开发者社区、接口文档与账号设置。深色紫黑视觉，单文件前端实现，封面与图片全部内联，开箱即用。

## 技术形态

- 原生 HTML / CSS / JavaScript，无构建步骤；运行时仅按需从 CDN 加载 `@supabase/supabase-js`。
- 所有图片以 base64 内联在 `index.html` 中，可直接双击打开。
- 游戏、资源、渠道、日志、帖子、成员六类列表接入 Supabase 数据层；未配置或拉取失败时自动回退内置示例数据，离线也能打开。
- 已接入 Supabase Auth 邮箱密码登录：未登录仅可浏览，发帖、点赞、渠道开关等写操作需登录后回写数据库；权限由数据库 RLS 策略控制。

## 目录结构

```
devrealm-platform/
├── index.html              # 单文件前端原型（内联样式 / 脚本 / 图片）
├── README.md
├── .gitignore
├── schema.sql              # Supabase（Postgres）建表脚本与 RLS 预留
└── seed.sql                # 演示示例数据导入脚本（建表后执行）
```

## 本地运行

直接用浏览器打开 `index.html` 即可；或在本目录启动一个静态服务：

```bash
# 任选其一
python3 -m http.server 8080
npx serve .
```

访问 `http://localhost:8080`。

## 页面清单

| 路由 | 页面 | 说明 |
| --- | --- | --- |
| overview | 概览 | 监控指标、学院教程、最新文章、Top 5 游戏 |
| games | 游戏库 | 已接入作品、KPI 与评分排行 |
| ranking | 排行榜 | 按综合评分排序 |
| users | 成员管理 | 成员、角色、项目数与在线状态 |
| api | API 调试 | 请求构造与响应示例 |
| assets | 资源库 | 插件 / SDK / 美术 / 音效 / 工具链 |
| link | 第三方接入 | Steam / Discord / itch 渠道开关 |
| monitor | 监控日志 | 接口耗时、警告与错误记录 |
| community | 开发者社区 | 发帖框、帖子流、最新游戏封面 |
| docs | 接口文档 | 资源 / 渠道 / 日志接口说明 |
| settings | 账号设置 | 个人资料与通知偏好 |

## 接入 Supabase

1. 在 Supabase 新建项目，打开 SQL Editor，先执行 `schema.sql` 完成建表；需要演示数据时再执行 `seed.sql` 灌入示例数据。
2. 在 `index.html` 的 `SUPABASE_CONFIG` 中填入项目 URL 与 `anonKey`：
   ```js
   const SUPABASE_CONFIG = { url: 'https://<project>.supabase.co', anonKey: '<anon-key>' };
   ```
3. 前端已内置远程加载逻辑：填好配置后会自动从 `games / resources / channels / logs / posts / profiles` 拉取数据；任一环节失败或留空配置时，自动回退到页面内置的本地示例数据，离线双击也能打开。
4. 登录鉴权：在 Supabase Authentication 中创建演示账号，并在 `profiles` 表用 `auth_id` 列把账号绑定到对应成员档案；RLS 策略（见 `schema.sql` 末尾）对所有人开放只读，发帖 / 点赞 / 渠道更新仅对 `authenticated` 角色放行。`service_role` 密钥仅限服务端使用，不得写入前端。

## 演示账号

| 登录账号 | 密码 | 身份 | 说明 |
| --- | --- | --- | --- |
| `admin` | `admin123` | 管理员（陶云） | 登录后可发帖、点赞、切换渠道 |
| `dev` | `Devrealm123` | 开发者（李承宇） | 普通成员，写操作权限同上 |

> Supabase 登录只识别邮箱格式，账号框输入 `admin` / `dev` 会自动补全为 `admin@example.com` / `dev@example.com`。

## 部署到 GitHub Pages

1. 在 GitHub 新建仓库，将本目录推送上去。
2. 仓库 Settings → Pages → Source 选择 `main` 分支根目录，保存后即可通过 Pages 地址访问。

## 当前限制

已接真实数据 / 鉴权 / 写回：

- 六类列表（游戏、资源、渠道、日志、帖子、成员）从 Supabase 加载；通知中心由 WARN / ERROR 日志与最新帖子生成；日志可导出 CSV；Top 5 支持按评分 / 下载量排序；API 调试页向后端发起真实只读查询；通知偏好与个人资料保存在浏览器本地。
- 邮箱密码登录 / 登出与会话恢复；顶部身份按当前登录用户回填；发帖写入 `posts`、点赞更新 `posts.likes`、渠道开关更新 `channels.enabled`，均经 RLS 校验后回写数据库。

仍为演示占位：

- 新用户自助注册、找回密码、修改密码流程未开放（演示账号在后台统一创建）。
- 上传资源 / 图片、新建游戏、邀请成员、2FA、列表筛选等为演示占位。
- 点赞未做跨设备防重复，仅按浏览器本地状态记录是否已赞。
