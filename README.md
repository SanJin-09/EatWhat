# EatWhat（吃什么？）

## 项目简介
EatWhat 是一款面向中国在校大学生的 iOS 校园饮食应用，聚焦“记录吃什么 + 推荐吃什么 + 校内店铺地图”三条主线。

当前仓库采用 **iOS App + 后端 API + 本地基础设施（Docker）** 的结构，正在从单机原型逐步演进到可联调的前后端版本。

## 产品目标（当前阶段）
- 让用户快速记录每次用餐（目标路径约 30 秒内完成）。
- 在校内场景下，基于历史记录提供按餐次推荐。
- 在地图上查看校内店铺，并支持后续扩展评价与推荐。
- 为后续营养分析、跨设备同步、图片展示等能力打好数据基础。

## 功能状态总览

### 已实现

#### 1) iOS：推荐页（`推荐` Tab）
- 基于时间段显示问候语（早上/中午/下午/晚上）与对应餐次推荐文案。
- Hero 卡片展示当前餐次推荐菜品与店铺。
- 冷启动提示（记录较少时显示）。
- 支持手动刷新推荐。
- 推荐算法为本地规则引擎：
  - 取最近 30 天历史记录；
  - 按早餐/午餐/晚餐分别聚合 `店铺+菜品`；
  - 按“频次 + 新鲜度”打分选 Top1；
  - 无历史时走内置 fallback 菜单。

#### 2) iOS：记录页（`记录` Tab）
- 完整 CRUD：新增/查询/编辑/删除饮食记录。
- 新增记录 Sheet 支持地图选店：
  - MapKit 地图；
  - 以定位或默认校区中心作为起点；
  - 拖动地图后自动按最近店铺联动；
  - 店铺变更后菜品列表联动更新；
  - 菜品可选“其他（手动填写）”；
  - 价格自动填充且可手动覆盖；
  - 餐次按时间自动判定，可手动改。
- 记录本地持久化采用 SwiftData。
- 记录结构已包含：`storeId`、`dishId`、快照字段与营养快照（6项）。

#### 3) iOS：店铺页（`店铺` Tab）
- 全屏 MapKit 地图（校内场景）。
- 顶部校区信息卡片 + 校区详情半屏 Sheet。
- 店铺标注点击后弹出底部半屏店铺信息。
- 当前支持从后端拉取店铺数据，并并发拉取每个店铺的菜品提示。

#### 4) 后端 API（NestJS）
- 健康检查：`GET /health`
- 校区店铺列表：`GET /campuses/:campusId/stores`
- 店铺菜品列表：`GET /stores/:storeId/dishes`
  - 返回价格、营养6项；
  - 已支持图片 URL 字段 `imageUrl`（由 `imageKey` 拼接）。

#### 5) 数据层（Prisma + PostgreSQL）
- 已建核心业务模型：
  - `Campus`（校区）
  - `User`（用户）
  - `CampusStore`（店铺）
  - `StoreDish`（菜品）
  - `MealLog`（饮食记录）
  - `StoreReview`（店铺评价）
- `StoreDish` 已扩展 `imageKey` 字段，用于对象存储图片定位。
- Seed 已写入南信大校区样例店铺与菜品（含营养数据）。

#### 6) 图片存储能力（后端）
- 接入 MinIO（S3 兼容）作为对象存储。
- 提供后台导入脚本：按文件命名规则上传菜品图片并回写 `imageKey`。
- API 查询时拼接公开访问 URL 返回给客户端。

---

### 未实现 / 进行中

#### 1) iOS 业务能力
- `营养` Tab：仍为占位页面，暂无完整可视化分析页。
- `我的` Tab：仍为占位页面，暂无用户信息、设置与偏好管理。
- 菜品图片 UI：后端已支持 `imageUrl`，前端展示链路尚未完整落地。
- 店铺评价流程：客户端完整提交/查看/排序能力尚未落地。

#### 2) 后端业务能力
- 用户认证与账户体系（注册/登录/鉴权）未实现。
- 饮食记录写入后端（`POST/PUT/DELETE /meal-logs`）尚未完成。
- 店铺评价接口（创建、查询、聚合）尚未完成。
- 推荐服务端化与更细粒度个性化排序未完成。

#### 3) 数据与产品化
- 真实生产级菜单与店铺运营流程（后台管理、审核、发布）未建立。
- 图片管理目前是后台脚本导入，尚未建设完整管理后台。
- 多校区支持、跨校区切换策略尚未落地。

## 前后端技术与语言

### iOS 端
- **语言**：Swift
- **UI 框架**：SwiftUI
- **地图能力**：MapKit + CoreLocation
- **本地存储**：SwiftData
- **网络通信**：URLSession（封装在 `CoreNetworking`）
- **工程组织**：
  - Xcode 工程 + Swift Package（本地模块化）
  - Core/Feature 分层
  - MVVM + UseCase + Repository

#### iOS 本地模块（Swift Packages）
- Core：`CoreDomain`、`CoreNetworking`、`CoreStorage`、`CoreFoundationKit`、`CoreDesignSystem`、`CoreAnalytics`
- Feature：`FeatureRecommendation`、`FeatureMealLog`、`FeatureCampusStore`、`FeatureNutrition`、`FeatureReview`、`FeatureProfileSettings`、`FeatureAuthOnboarding`

> 其中 `FeatureNutrition / FeatureReview / FeatureProfileSettings / FeatureAuthOnboarding` 当前主要为模块占位，业务实现尚未展开。

### 后端
- **语言**：TypeScript
- **运行时**：Node.js
- **Web 框架**：NestJS
- **ORM**：Prisma
- **数据库**：PostgreSQL（镜像采用 PostGIS 版本）
- **缓存/中间件**：Redis（基础设施已接入，业务使用待扩展）
- **对象存储**：MinIO（S3 兼容）
- **容器编排**：Docker Compose

### 数据与接口约定
- API 以 REST 风格为主，当前已对接“校区店铺 + 店铺菜品”两条读接口。
- 菜品营养字段采用 6 项快照：
  - `caloriesKcal`、`proteinG`、`fatG`、`carbG`、`sodiumMg`、`fiberG`
- 图片采用“数据库存 key、接口返回 URL”的分离策略，避免二进制入库。

## 当前后端数据库结构（业务层）
- `Campus`：校区信息（`code` 主键）
- `User`：用户基础信息与校区归属
- `CampusStore`：校区店铺（名称、区域、坐标、营业状态）
- `StoreDish`：菜品（价格、营养、可用状态、`imageKey`）
- `MealLog`：用户饮食记录（餐次、时间、店铺/菜品引用与快照）
- `StoreReview`：店铺评价（评分、文本、推荐菜）

## 当前目录结构（简化）
```text
EatWhat/
├─ EatWhat/                         # iOS App 工程（AppShell + Configs）
├─ Packages/                        # Swift 本地模块（Core + Feature）
├─ backend/
│  ├─ apps/api/                     # NestJS API
│  │  ├─ src/                       # controller/service/module
│  │  ├─ prisma/                    # schema/migrations/seed
│  │  └─ scripts/                   # 媒体上传脚本
│  └─ docker-compose.yml            # postgres/redis/minio
├─ Podfile
└─ EatWhat.xcworkspace
```

## 项目阶段结论
当前项目已完成“可用原型到可联调版本”的关键跨越：
- 前端可记录、可推荐、可看店铺地图；
- 后端可提供店铺/菜品真实数据；
- 数据库与图片存储链路已具备扩展能力。

下一阶段建议重点是：
- 打通后端饮食记录写接口与用户体系；
- 完成营养页和个人页；
- 建立店铺评价与图片展示闭环；
- 将推荐从本地规则逐步升级为服务端个性化模型。

---

如需查看更早期产品文档，可参考：
- `EatWhat_iOS_PRD_and_Swift_Modules.md`
