# EatWhat 后端 Docker 方案书与操作指南（现阶段）

## 1. 目标与范围

本方案面向你当前 iOS App 的真实开发状态，目标是：

1. 先把最小可用后端跑起来，支撑现有功能联调。
2. 全流程本地 Docker 化，保证环境一致和可迁移到云端。
3. 保留后续扩展（评价、推荐、多校区、多环境）的演进空间。

当前优先支持的业务能力：

1. 校内店铺列表（含坐标）
2. 店铺菜品列表（含价格、营养）
3. 饮食记录 CRUD
4. 基础健康检查与鉴权占位

---

## 2. 技术栈建议（MVP）

后端语言与框架建议：

1. `NestJS + TypeScript`（开发效率和工程规范较平衡）
2. `Prisma`（数据库模型管理 + Migration + Seed）
3. `PostgreSQL 16`（主库）
4. `PostGIS`（店铺地理查询能力）
5. `Redis 7`（先接入，后续用于缓存和推荐中间结果）
6. `Nginx`（可选，后续统一网关）

为什么这样选：

1. 对移动端联调友好，接口定义清晰。
2. Prisma 对迭代快、字段变化频繁的前期很友好。
3. PostGIS 能直接支持“最近店铺”与地理范围查询。

---

## 3. 本地目录规划

在仓库根目录新增：

```text
backend/
  apps/
    api/                     # NestJS 服务
  prisma/
    schema.prisma
    migrations/
    seed.ts
  docker/
    postgres/
      init.sql               # 扩展、初始函数
  .env.example
  .env
  docker-compose.yml
```

说明：

1. `backend/` 与 iOS 工程平级，便于你以后在同一个仓库协作。
2. 所有基础设施（DB/Redis）统一走 Docker。

---

## 4. 容器与端口规划

建议端口（可按你机器情况调整）：

1. API：`8080`
2. PostgreSQL：`5432`
3. Redis：`6379`
4. PgAdmin（可选）：`5050`

服务清单：

1. `eatwhat-api`
2. `eatwhat-postgres`
3. `eatwhat-redis`
4. `eatwhat-pgadmin`（可选）

---

## 5. docker-compose（建议基线）

> 你可以先按这份起步，后续我可以帮你直接落文件。

```yaml
version: "3.9"

services:
  postgres:
    image: postgis/postgis:16-3.4
    container_name: eatwhat-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: eatwhat
      POSTGRES_PASSWORD: eatwhat_dev_pwd
      POSTGRES_DB: eatwhat
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U eatwhat -d eatwhat"]
      interval: 5s
      timeout: 3s
      retries: 20

  redis:
    image: redis:7-alpine
    container_name: eatwhat-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  api:
    build:
      context: ./apps/api
      dockerfile: Dockerfile
    container_name: eatwhat-api
    restart: unless-stopped
    env_file:
      - .env
    environment:
      DATABASE_URL: postgresql://eatwhat:eatwhat_dev_pwd@postgres:5432/eatwhat?schema=public
      REDIS_URL: redis://redis:6379
      NODE_ENV: development
      PORT: 8080
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started

volumes:
  postgres_data:
  redis_data:
```

---

## 6. 数据库模型（MVP 必备）

先做这些核心表：

1. `users`
2. `campuses`
3. `campus_stores`
4. `store_dishes`
5. `meal_logs`
6. `store_reviews`（先建表，可后接接口）

关键字段建议：

1. `campus_stores`
   - `id, campus_id, name, area, location(geography(Point,4326)), is_open`
2. `store_dishes`
   - `id, store_id, name, price, calories_kcal, protein_g, fat_g, carb_g, sodium_mg, fiber_g, is_available`
3. `meal_logs`
   - `id, user_id, store_id, dish_id, store_name_snapshot, dish_name_snapshot, price_snapshot, meal_type, logged_at, nutrition_snapshot(jsonb)`

必建索引：

1. `campus_stores`：`GIST(location)`
2. `meal_logs(user_id, logged_at desc)`
3. `meal_logs(user_id, meal_type, logged_at desc)`
4. `store_dishes(store_id, is_available)`

---

## 7. 接口契约（对齐你现有 App）

你现在 App 已经对接了菜单仓库，这两个接口要先落地：

1. `GET /campuses/{campusId}/stores`
2. `GET /stores/{storeId}/dishes`

建议响应格式（和你当前 iOS 兼容）：

1. 支持数组：`[ ... ]`
2. 或包裹对象：`{ "stores": [...] }` / `{ "dishes": [...] }`

接下来马上补齐：

1. `POST /meal-logs`
2. `GET /meal-logs?userId=...`
3. `PATCH /meal-logs/{id}`
4. `DELETE /meal-logs/{id}`

---

## 8. iOS 联调配置

你当前 iOS 已支持 `CampusMenuAPIBaseURL`，联调时设置：

`/Users/sanjin/XcodeProject/EatWhat/EatWhat/Configs/LocalSecrets.xcconfig`

```xcconfig
CAMPUS_MENU_API_BASE_URL = http://127.0.0.1:8080
```

说明：

1. 模拟器可直接访问 `127.0.0.1:8080`。
2. 真机调试时建议改成你 Mac 的局域网 IP（例如 `http://192.168.x.x:8080`）。

---

## 9. 逐步操作指南（从 0 到可跑）

### 第一步：安装工具

1. 安装 Docker Desktop（Mac）
2. 安装 Node.js 20+（建议 `nvm`）
3. 安装 pnpm（可选）

### 第二步：初始化 backend 目录

在仓库根目录执行（示例）：

```bash
mkdir -p backend && cd backend
mkdir -p apps/api prisma docker/postgres
```

### 第三步：准备环境变量

创建 `backend/.env`：

```env
DATABASE_URL=postgresql://eatwhat:eatwhat_dev_pwd@postgres:5432/eatwhat?schema=public
REDIS_URL=redis://redis:6379
JWT_SECRET=dev_only_change_me
PORT=8080
```

### 第四步：写 docker-compose 并启动基础设施

```bash
cd backend
docker compose up -d postgres redis
docker compose ps
```

### 第五步：初始化 API（NestJS）

```bash
cd backend/apps
npx @nestjs/cli new api
```

把 API Dockerfile 配好后，回到 `backend/`：

```bash
docker compose up -d --build api
docker compose logs -f api
```

### 第六步：Prisma 建模与迁移

```bash
cd backend/apps/api
npx prisma init
```

更新 `schema.prisma` 后执行：

```bash
npx prisma migrate dev --name init
npx prisma db seed
```

### 第七步：本地验收

1. 访问 `GET http://127.0.0.1:8080/health`
2. 访问 `GET http://127.0.0.1:8080/campuses/nuist/stores`
3. 访问 `GET http://127.0.0.1:8080/stores/{storeId}/dishes`
4. iOS 切换 `CAMPUS_MENU_API_BASE_URL` 后验证页面有真实数据

---

## 10. 数据初始化建议（南信大）

先准备一份种子数据：

1. 校区：`nuist`
2. 店铺：一食堂、二食堂、北门早餐铺、东苑等
3. 菜品：每店 10-20 个高频菜
4. 每个菜品带价格 + 营养六项（可先估值，后续迭代精确）

原则：

1. 字段完整优先于数据完美。
2. 先保证“可用且稳定”，再逐步提精度。

---

## 11. 安全与运维基线（前期就要做）

1. `.env` 不入库，提交 `.env.example`。
2. 数据库每天自动备份（开发环境可每周一次）。
3. 所有写接口加基础鉴权（即使先用简化 JWT）。
4. 接口层统一参数校验（DTO + class-validator）。
5. 错误码与日志结构统一（便于 iOS 端兜底）。

---

## 12. 分阶段里程碑（建议）

### 里程碑 A（1-2 天）

1. Docker 基础设施跑通（Postgres/Redis/API）
2. `stores` + `dishes` 两个接口跑通
3. iOS 已切到本地真实 API

### 里程碑 B（2-4 天）

1. `meal_logs` 全 CRUD
2. 与 iOS 记录页联调稳定
3. 基础鉴权 + 统一错误码

### 里程碑 C（后续）

1. 评价体系接口
2. 推荐接口后端化
3. 上云部署（测试环境 -> 生产环境）

---

## 13. 你现在可以直接执行的命令（最小起步）

```bash
cd /Users/sanjin/XcodeProject/EatWhat
mkdir -p backend/apps/api backend/prisma backend/docker/postgres
cd backend
docker compose up -d postgres redis
```

如果你希望，我下一步可以直接帮你在 `backend/` 下落地第一版可运行脚手架（`docker-compose + NestJS + Prisma schema + seed + health/stores/dishes`），你打开 Docker 后就能一键启动联调。
