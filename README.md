# DevRealm · 游戏开发者服务平台

面向独立游戏团队的开发者控制台原型：数据看板、游戏库、排行榜、API 调试、资源库、渠道接入、监控日志、开发者社区、接口文档与账号设置。深色紫黑视觉，单文件前端实现，封面与图片全部内联，开箱即用。

## 技术形态

- 原生 HTML / CSS / JavaScript，无构建步骤、无第三方运行时依赖。
- 所有图片以 base64 内联在 `index.html` 中，可直接双击打开。
- 当前为**前端高保真原型**：列表、帖子、日志等均为内置示例数据，尚未接入真实后端与登录鉴权。

## 目录结构

```
devrealm-platform/
├── index.html              # 单文件前端原型（内联样式 / 脚本 / 图片）
├── README.md
├── .gitignore
└── supabase/
    └── schema.sql          # Supabase（Postgres）建表脚本与 RLS 预留
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

1. 在 Supabase 新建项目，打开 SQL Editor，执行 `supabase/schema.sql` 完成建表。
2. 在 `index.html` 的数据层预留处，填入项目 URL 与 `anonKey`：
   ```js
   const SUPABASE_CONFIG = { url: 'https://<project>.supabase.co', anonKey: '<anon-key>' };
   ```
3. 引入 `@supabase/supabase-js`，把视图中的本地示例常量替换为 `client.from('表名').select()` 异步查询。
4. 权限策略见 `schema.sql` 末尾的 RLS 预留；`service_role` 密钥仅限服务端使用，不得写入前端。

## 部署到 GitHub Pages

1. 在 GitHub 新建仓库，将本目录推送上去。
2. 仓库 Settings → Pages → Source 选择 `main` 分支根目录，保存后即可通过 Pages 地址访问。

## 当前限制

- 未实现真实注册 / 登录与鉴权，页面身份为演示占位。
- 发帖、点赞、渠道开关、上传等操作仅更新前端状态，不持久化。
- 图表、导出、通知中心为演示占位，未接真实服务。
