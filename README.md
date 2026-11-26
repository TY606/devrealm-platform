# DevRealm · 游戏开发者服务平台

面向独立游戏团队的开发者控制台原型：数据看板、游戏库、排行榜、API 调试、资源库、渠道接入、监控日志、开发者社区、接口文档与账号设置。深色紫黑视觉，单文件前端实现，封面与图片全部内联，开箱即用。

## 技术形态

- 原生 HTML / CSS / JavaScript，无构建步骤；运行时按需从 CDN 加载 `@supabase/supabase-js`，3D 编辑器按需加载 `three.js`。
- 所有图片以 base64 内联在 `index.html` 中，可直接双击打开。
- 游戏、资源、渠道、日志、帖子、成员六类列表接入 Supabase 数据层；未配置或拉取失败时自动回退内置示例数据，离线也能打开。
- 已接入 Supabase Auth 邮箱密码登录：未登录仅可浏览，发帖、点赞、渠道开关等写操作需登录后回写数据库；权限由数据库 RLS 策略控制。

## 目录结构

```
devrealm-platform/
├── index.html              # 单文件前端原型（内联样式 / 脚本 / 图片）
├── README.md
├── .gitignore
├── schema.sql              # Supabase（Postgres）基础建表脚本与 RLS 预留
├── seed.sql                # 演示示例数据导入脚本（建表后执行）
├── migration_v2.sql         # 二期迁移：评论/任务/消息/分享/审计表、RLS、管理员函数与注册自动建档触发器
├── migration_v3.sql         # 三期迁移：工作台项目表 projects、profiles 头像字段与对应 RLS
└── desktop/                 # Electron 桌面套壳骨架（主进程 + 打包配置），加载上级 index.html
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
| admin | 管理后台 | 仅管理员可见：数据总览、内容增删改查、风险预警、安全检查、审计日志；登录后按角色分流到对应首页 |

## 接入 Supabase

1. 在 Supabase 新建项目，打开 SQL Editor，先执行 `schema.sql` 完成基础建表；再依次执行 `migration_v2.sql`、`migration_v3.sql` 补齐各期表与策略；需要演示数据时最后执行 `seed.sql` 灌入示例数据。
2. 在 `index.html` 的 `SUPABASE_CONFIG` 中填入项目 URL 与 `anonKey`：
   ```js
   const SUPABASE_CONFIG = { url: 'https://<project>.supabase.co', anonKey: '<anon-key>' };
   ```
3. 前端已内置远程加载逻辑：填好配置后会自动从 `games / resources / channels / logs / posts / profiles / comments / tasks / messages / shares / audit_logs` 拉取数据；任一环节失败或留空配置时，自动回退到页面内置的本地示例数据，离线双击也能打开。
4. 登录鉴权：在 Supabase Authentication 中创建演示账号，并在 `profiles` 表用 `auth_id` 列把账号绑定到对应成员档案；RLS 策略对所有人开放只读，发帖 / 评论 / 任务 / 消息 / 分享等写操作仅对 `authenticated` 角色放行，内容管理（增删改）仅 `admin` 角色放行。`service_role` 密钥仅限服务端使用，不得写入前端。
5. 自助注册：新用户在登录页切换到注册表单即可创建账号；`migration_v2.sql` 中的 `handle_new_user` 触发器会在注册成功后自动为其插入一条 `role = dev` 的普通开发者档案（邮箱冲突时不重复建档）。若项目开启了邮箱确认，新用户需先点击邮件确认链接再登录。

## 演示账号

| 登录账号 | 密码 | 身份 | 说明 |
| --- | --- | --- | --- |
| `admin` | `admin123` | 管理员（陶云） | 登录后可发帖、点赞、切换渠道 |
| `dev` | `Devrealm123` | 开发者（李承宇） | 普通成员，写操作权限同上 |

> Supabase 登录只识别邮箱格式，账号框输入 `admin` / `dev` 会自动补全为 `admin@example.com` / `dev@example.com`。

## 部署到 GitHub Pages

1. 在 GitHub 新建仓库，将本目录推送上去。
2. 仓库 Settings → Pages → Source 选择 `main` 分支根目录，保存后即可通过 Pages 地址访问。

## 打包成电脑应用（Electron 套壳）

`desktop/` 目录是把现有单文件前端套成桌面应用的骨架，业务代码无需改动：

```bash
cd desktop
npm install        # 安装 electron 与 electron-builder
npm start          # 本地启动桌面窗口预览
npm run build:win  # 导出 Windows 安装包（nsis）到 desktop/dist
npm run build:mac  # 导出 macOS dmg（需在 Mac 上签名打包）
npm run build:linux # 导出 Linux AppImage
```

- 主进程 `desktop/main.js` 创建窗口并加载上级目录的 `index.html`；`preload.js` 通过 contextBridge 暴露受限本地接口（工程 JSON 保存 / 打开、本地资源文件选择）；外部链接交系统浏览器打开。
- 前端探测到 `window.devRealmAPI` 才显示"导出本地工程"等桌面入口，浏览器版自动降级为本地存储 / 云端，不报错。
- 套壳只把网页装进桌面窗口，不改变前端技术栈；打包需在装有 Node.js 的机器（或云端流水线）上执行；iOS / 安卓手机端不在本骨架范围内。

## 当前限制

已接真实数据 / 鉴权 / 写回：

- 六类列表（游戏、资源、渠道、日志、帖子、成员）从 Supabase 加载；通知中心由 WARN / ERROR 日志与最新帖子生成；日志可导出 CSV；Top 5 支持按评分 / 下载量排序；API 调试页向后端发起真实只读查询；通知偏好与个人资料保存在浏览器本地。
- 邮箱密码登录 / 登出与会话恢复；顶部身份按当前登录用户回填；发帖写入 `posts`、点赞更新 `posts.likes`、渠道开关更新 `channels.enabled`，均经 RLS 校验后回写数据库。
- 详情弹窗含项目说明、开发文档、下载链接与评论区；评论写入 `comments`，成员协作的消息、任务、资源分享分别写入 `messages / tasks / shares`，管理员操作记入 `audit_logs`。
- 管理员独立后台：数据总览、游戏 / 帖子 / 资源 / 成员 / 渠道五类内容的新增、编辑、删除，风险预警由 WARN / ERROR 日志生成；登录后按 `role` 分流，管理员进后台、开发者进概览。
- 自助注册开放：注册成功经触发器自动建档为普通开发者（`role = dev`）；注册表单带前端图形验证码（canvas 字符 + 干扰线），校验通过才可提交。
- 开发工作台：从模板新建项目，分 2D / 3D 两类。2D 项目内置代码编辑区与 Canvas 实时预览，可运行、停止、保存；3D 项目为 Three.js 场景编辑器：视口拖拽旋转 / 滚轮缩放、实体列表选中联动、属性面板改位置 / 缩放 / 颜色 / 形状 / 材质 / 粗糙度 / 金属度 / 刚体类型 / 动画，贴图上传赋材质，支持导入 `.glb` 模型（自动按包围盒缩放居中、底部落地）并在其多段动画间切换播放，WASD / 方向键 + 空格跳跃操控选中实体，内置 cannon.js 物理（重力、刚体碰撞、落地静止，可启停），桌面版可浏览本地资源目录并一键赋给实体；场景序列化为 JSON 存入 `projects.code`，可重新打开恢复。项目写入 `projects` 表，未登录或写库失败时保留浏览器本地。
- 头像可修改：支持上传本地图片（压缩为小尺寸 dataURL）或从内置头像库挑选，写入 `profiles.avatar`，顶部、成员列表与评论等处统一展示。

仍为演示占位：

- 作品封面图上传、2FA、找回密码、列表高级筛选等为演示占位；后台新增记录时图片字段沿用内置占位封面。
- 点赞未做跨设备防重复，仅按浏览器本地状态记录是否已赞。
- 3D 编辑器当前为 MVP：七种基础网格 + 标准 / 基础 / 线框三种材质；可导入 `.glb` 模型并下拉切换其各段动画，内置自转 / 浮动两种简单动画，WASD / 方向键移动、空格跳跃（物理开启时作用于刚体速度与冲量）。物理仅对立方体 / 球体 / 平面做精确刚体，其余形状以包围盒近似。未接入 FBX 模型、蒙皮骨骼编辑、材质节点、动画时间轴关键帧编辑、复杂角色控制器（跑步 / 攀爬 / 动画融合）；桌面资源目录仅列出前 30 个、单文件小于 2MB 的资源并读成 dataURL。模型以 dataURL 随工程保存，大模型会撑大工程文件。导出产物为场景 JSON 与 Web 可运行版本，桌面套壳可打包成电脑应用并读写本地工程文件，但不生成原生游戏安装包。WebGL 不可用的环境（部分沙箱 / 旧设备）下视口降级为提示文案，实体编辑与保存仍可用。
