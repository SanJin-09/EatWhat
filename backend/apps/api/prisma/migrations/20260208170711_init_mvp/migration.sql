-- CreateEnum
CREATE TYPE "MealType" AS ENUM ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK');

-- CreateTable
CREATE TABLE "Campus" (
    "code" VARCHAR(32) NOT NULL,
    "name" TEXT NOT NULL,
    "city" TEXT,
    "centerLat" DECIMAL(9,6),
    "centerLng" DECIMAL(9,6),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Campus_pkey" PRIMARY KEY ("code")
);

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "campusCode" VARCHAR(32),
    "nickname" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CampusStore" (
    "id" UUID NOT NULL,
    "campusCode" VARCHAR(32) NOT NULL,
    "name" TEXT NOT NULL,
    "area" TEXT NOT NULL,
    "latitude" DECIMAL(9,6) NOT NULL,
    "longitude" DECIMAL(9,6) NOT NULL,
    "isOpen" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CampusStore_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreDish" (
    "id" UUID NOT NULL,
    "storeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "price" DECIMAL(10,2),
    "caloriesKcal" DECIMAL(10,2),
    "proteinG" DECIMAL(10,2),
    "fatG" DECIMAL(10,2),
    "carbG" DECIMAL(10,2),
    "sodiumMg" DECIMAL(10,2),
    "fiberG" DECIMAL(10,2),
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StoreDish_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MealLog" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "loggedAt" TIMESTAMP(3) NOT NULL,
    "mealType" "MealType" NOT NULL,
    "storeId" UUID,
    "dishId" UUID,
    "storeNameSnapshot" TEXT NOT NULL,
    "dishNameSnapshot" TEXT NOT NULL,
    "priceSnapshot" DECIMAL(10,2),
    "nutritionSnapshot" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MealLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreReview" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "storeId" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "content" TEXT,
    "recommendedDish" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StoreReview_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "User_campusCode_idx" ON "User"("campusCode");

-- CreateIndex
CREATE INDEX "CampusStore_campusCode_idx" ON "CampusStore"("campusCode");

-- CreateIndex
CREATE INDEX "CampusStore_campusCode_name_idx" ON "CampusStore"("campusCode", "name");

-- CreateIndex
CREATE INDEX "CampusStore_latitude_longitude_idx" ON "CampusStore"("latitude", "longitude");

-- CreateIndex
CREATE UNIQUE INDEX "CampusStore_campusCode_name_area_key" ON "CampusStore"("campusCode", "name", "area");

-- CreateIndex
CREATE INDEX "StoreDish_storeId_isAvailable_idx" ON "StoreDish"("storeId", "isAvailable");

-- CreateIndex
CREATE INDEX "StoreDish_storeId_name_idx" ON "StoreDish"("storeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "StoreDish_storeId_name_key" ON "StoreDish"("storeId", "name");

-- CreateIndex
CREATE INDEX "MealLog_userId_loggedAt_idx" ON "MealLog"("userId", "loggedAt" DESC);

-- CreateIndex
CREATE INDEX "MealLog_userId_mealType_loggedAt_idx" ON "MealLog"("userId", "mealType", "loggedAt" DESC);

-- CreateIndex
CREATE INDEX "MealLog_storeId_loggedAt_idx" ON "MealLog"("storeId", "loggedAt" DESC);

-- CreateIndex
CREATE INDEX "MealLog_dishId_loggedAt_idx" ON "MealLog"("dishId", "loggedAt" DESC);

-- CreateIndex
CREATE INDEX "StoreReview_storeId_createdAt_idx" ON "StoreReview"("storeId", "createdAt" DESC);

-- CreateIndex
CREATE INDEX "StoreReview_userId_createdAt_idx" ON "StoreReview"("userId", "createdAt" DESC);

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_campusCode_fkey" FOREIGN KEY ("campusCode") REFERENCES "Campus"("code") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CampusStore" ADD CONSTRAINT "CampusStore_campusCode_fkey" FOREIGN KEY ("campusCode") REFERENCES "Campus"("code") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreDish" ADD CONSTRAINT "StoreDish_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "CampusStore"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealLog" ADD CONSTRAINT "MealLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealLog" ADD CONSTRAINT "MealLog_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "CampusStore"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealLog" ADD CONSTRAINT "MealLog_dishId_fkey" FOREIGN KEY ("dishId") REFERENCES "StoreDish"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreReview" ADD CONSTRAINT "StoreReview_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreReview" ADD CONSTRAINT "StoreReview_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "CampusStore"("id") ON DELETE CASCADE ON UPDATE CASCADE;
