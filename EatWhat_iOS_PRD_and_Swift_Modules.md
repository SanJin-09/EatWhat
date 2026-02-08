# EatWhat iOS 可开发 PRD 目录 + Swift 端模块划分（v0.1）

## 0. 使用说明
- 本文档用于快速启动研发，先按目录补全 PRD，再按模块拆分工程并并行开发。
- 技术默认：`Swift 5.10+`、`iOS 17+`、`SwiftUI`、`SwiftData`、`SPM`、`async/await`。
- 用户范围：同校大学生，优先校园内用餐场景。

---

## A. 可开发 PRD 目录（建议直接按此写完整 PRD）

## 1. 文档信息
- 文档名：EatWhat 产品需求文档
- 版本号 / 状态（Draft、Review、Approved）
- 作者 / 评审人 / 更新时间
- 关联文档：交互稿、接口文档、埋点文档、测试用例

## 2. 背景与目标
- 业务背景：大学生“吃什么”决策困难，营养结构不均衡。
- 产品目标：
  - 降低三餐决策时间
  - 提升饮食记录连续性
  - 提供可执行营养建议
- 北极星指标（NSM）：推荐被采纳率（推荐菜品被记录的比例）

## 3. 用户画像与核心场景
- 目标用户：18-24 岁在校大学生（本科/研究生）
- 核心场景：
  - 赶课间快速决策午餐
  - 控制预算与体重
  - 想吃得健康但不想复杂计算
- 角色划分：
  - 普通用户
  - 校园内容管理员（后续）

## 4. 范围定义
- In Scope（V1~V2）：
  - 饮食记录
  - 营养分析可视化
  - 个性化三餐推荐（到店到菜）
  - 校园店铺地图与评分
- Out of Scope（后续）：
  - 外卖配送闭环
  - 复杂社交关系链（关注、私信）

## 5. 信息架构与主流程
- 主要 Tab：
  - 首页推荐
  - 记录
  - 校园店铺
  - 营养分析
  - 我的
- 关键流程：
  - 首次登录 -> 校园认证 -> 完善档案 -> 首页
  - 首页推荐 -> 查看推荐理由 -> 一键记录
  - 店铺页 -> 选菜 -> 评分评论 -> 同校可见

## 6. 功能需求明细（每个功能必须包含：规则、边界、验收、埋点）

## 6.1 账号与校园认证
- 支持手机号登录（验证码）
- 校园身份校验（校园邮箱/邀请码/管理员导入名单）
- 同校可见规则：仅学校字段一致的用户可见评论与评分流
- 验收标准：
  - 新用户 3 分钟内完成注册与认证
  - 认证失败可回退到游客态（仅浏览公开基础数据）

## 6.2 饮食记录
- 记录字段：时间段（早/午/晚/加餐）、店铺、菜品、份量、价格、备注
- 快捷录入：最近记录、收藏、复制昨日
- 规则：
  - 同餐时段可多条记录
  - 份量单位标准化（份/克/碗）
- 验收标准：
  - 单次记录操作 <= 20 秒
  - 记录可编辑、可删除、可追溯

## 6.3 营养分析与建议
- 输入：用户画像（性别、年龄、身高、体重、活动量）+ 饮食记录
- 输出：
  - 日/周能量与三大营养素达标率
  - 钠、膳食纤维等关键指标趋势
  - 文本建议（如“晚餐补充优质蛋白”）
- 规则：
  - 采用统一营养数据库口径（服务端下发版本号）
  - 对缺失份量按默认估值并标记“估算”
- 验收标准：
  - 每日计算任务完成率 > 99%
  - 图表加载 < 1.5s（本地缓存命中）

## 6.4 个性化推荐（首页开屏）
- 触发条件：有效记录 >= 15 条且覆盖 >= 7 天
- 推荐结果：早餐/午餐/晚餐各 1~3 条（店铺 + 菜品）
- 推荐因子（V1）：
  - 营养缺口匹配
  - 历史偏好
  - 价格区间
  - 距离与营业状态
- 推荐解释：每条结果展示 1~2 条“为什么推荐”
- 验收标准：
  - 推荐接口 P95 < 800ms
  - 推荐点击率、采纳率可被埋点追踪

## 6.5 校园店铺与地图
- 校内店铺全量维护：食堂、档口、独立商家
- 店铺数据：位置、营业时段、人均、主打菜、标签
- 筛选项：距离、价格、类别、健康标签（低脂/高蛋白等）
- 验收标准：
  - 可覆盖学校主要餐饮点 >= 90%
  - 地图页首屏加载 < 2s

## 6.6 评分与评论（同校可见）
- 评分维度：口味、分量、性价比、卫生、排队体验
- 评论可附图片（V2）
- 风控：
  - 频繁重复评论限流
  - 举报与审核机制
- 验收标准：
  - 评分发布成功率 > 99%
  - 评论内容审核状态可追踪

## 7. 数据需求
- 主实体：
  - UserProfile
  - School
  - Store
  - Dish
  - MealLog
  - NutritionSnapshot
  - Recommendation
  - Review
- 核心关系：
  - Store 1-N Dish
  - User 1-N MealLog
  - User 1-N Review
  - User 1-N Recommendation（日级）

## 8. 接口需求（PRD 中需补充 OpenAPI/字段定义）
- `POST /auth/login`
- `POST /schools/verify`
- `GET /stores`
- `GET /stores/{id}/dishes`
- `POST /meal-logs`
- `GET /nutrition/snapshots`
- `GET /recommendations/daily`
- `POST /reviews`
- `GET /reviews/feed?schoolId=`

## 9. 非功能需求
- 性能：冷启动 < 2.5s，页面切换 < 400ms
- 稳定性：Crash Free > 99.8%
- 安全：登录态加密存储、接口签名、防重放
- 隐私合规：明确定位和健康数据用途，支持账号注销

## 10. 埋点与指标体系
- 核心漏斗：启动 -> 首页曝光 -> 推荐点击 -> 记录采纳
- 关键事件：
  - `meal_log_created`
  - `recommendation_viewed`
  - `recommendation_accepted`
  - `store_review_submitted`
- 看板指标：
  - 7 日留存
  - 人均周记录次数
  - 推荐采纳率
  - 同校活跃评论率

## 11. 测试与验收计划
- 测试类型：单元测试、UI 测试、接口联调、灰度回归
- 发布策略：TestFlight 分校灰度 -> 全量发布
- 验收出口：
  - P0 缺陷为 0
  - 核心路径通过率 100%

## 12. 里程碑（建议）
- M1（2 周）：账号、基础记录、店铺列表
- M2（2 周）：营养分析图表、评分评论
- M3（2 周）：首页个性化推荐 + 推荐解释
- M4（1 周）：性能优化、灰度发布

---

## B. Swift 端模块划分（可直接建工程）

## 1. 工程组织建议
- 主工程：`EatWhatApp.xcodeproj`
- 代码拆分：`App + SPM Packages`
- 目标：高内聚、低耦合、可并行开发、可单测

## 2. 模块清单与职责

| 模块 | 责任 | 依赖 |
|---|---|---|
| AppShell | App 生命周期、路由入口、Tab 容器、DI 装配 | 所有 Feature + Core |
| CoreFoundationKit | 通用工具（日志、日期、扩展、错误模型） | 无 |
| CoreNetworking | HTTP Client、鉴权、重试、请求封装 | CoreFoundationKit |
| CoreStorage | SwiftData、本地缓存、Keychain | CoreFoundationKit |
| CoreDomain | 实体、DTO、Repository 协议、UseCase 协议 | CoreFoundationKit |
| CoreDesignSystem | 颜色、字体、组件库、图表样式 | CoreFoundationKit |
| CoreAnalytics | 埋点协议与实现 | CoreFoundationKit, CoreNetworking |
| FeatureAuthOnboarding | 登录、校园认证、用户档案初始化 | CoreDomain, CoreNetworking, CoreStorage |
| FeatureMealLog | 饮食记录增删改查、快捷录入 | CoreDomain, CoreStorage, CoreAnalytics |
| FeatureNutrition | 营养趋势、达标分析、建议展示 | CoreDomain, CoreNetworking, CoreDesignSystem |
| FeatureRecommendation | 首页三餐推荐、推荐解释、替换推荐 | CoreDomain, CoreNetworking, CoreAnalytics |
| FeatureCampusStore | 校园店铺列表/地图、店铺详情、菜品页 | CoreDomain, CoreNetworking, CoreDesignSystem |
| FeatureReview | 评分评论流、发布与举报 | CoreDomain, CoreNetworking, CoreAnalytics |
| FeatureProfileSettings | 个人信息、目标、隐私设置 | CoreDomain, CoreStorage |

## 3. 依赖约束（必须遵守）
- Feature 之间禁止直接依赖；通过 `CoreDomain` 协议通信。
- UI 层不直接调用网络；通过 UseCase/Repository。
- 不允许跨模块访问内部实现（使用 `public` 最小暴露）。

## 4. 推荐目录结构

```text
EatWhat/
  App/
    AppShell/
      EatWhatApp.swift
      AppRouter.swift
      DependencyContainer.swift
  Packages/
    CoreFoundationKit/
    CoreNetworking/
    CoreStorage/
    CoreDomain/
    CoreDesignSystem/
    CoreAnalytics/
    FeatureAuthOnboarding/
    FeatureMealLog/
    FeatureNutrition/
    FeatureRecommendation/
    FeatureCampusStore/
    FeatureReview/
    FeatureProfileSettings/
```

## 5. 模块内分层模板（每个 Feature 统一）

```text
FeatureX/
  Sources/
    FeatureX/
      Presentation/    # View, ViewModel, State
      Domain/          # UseCase
      Data/            # Repository Impl, Mapper
      Routing/         # Feature 内导航
  Tests/
    FeatureXTests/
```

## 6. 关键协议（建议先定义）
- `AuthRepository`
- `MealLogRepository`
- `NutritionRepository`
- `RecommendationRepository`
- `StoreRepository`
- `ReviewRepository`
- `AnalyticsTracking`
- `CacheStore`

## 7. 本地存储建议（SwiftData）
- 本地实体：
  - CachedUserProfile
  - CachedMealLog
  - CachedRecommendation
  - CachedStore
- 缓存策略：
  - 首页推荐：按日缓存，次日自动失效
  - 店铺列表：按学校缓存，支持手动刷新
  - 记录数据：本地优先写入，后台补同步

## 8. 并行开发分工建议
- A 组：`CoreFoundationKit + CoreNetworking + CoreDomain`
- B 组：`FeatureMealLog + FeatureCampusStore`
- C 组：`FeatureNutrition + FeatureRecommendation`
- D 组：`FeatureReview + FeatureProfileSettings + CoreAnalytics`

## 9. 质量门禁（iOS 侧）
- 每个模块单测覆盖核心 UseCase
- CI 最低要求：
  - 编译通过
  - 单测通过
  - SwiftLint 无阻断级告警
- 发布前：
  - 关键路径 UI Test（登录、记录、推荐采纳、评论）

---

## C. 开发启动清单（第一周）
- 建立 SPM 多模块骨架与依赖边界
- 定义 CoreDomain 实体与 Repository 协议
- 打通登录、店铺列表、记录新增三条最短业务链路
- 接入埋点基础框架并验证事件上报
- 输出第一版 API Mock 与联调清单
