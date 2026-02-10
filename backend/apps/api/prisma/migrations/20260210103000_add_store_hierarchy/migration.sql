-- CreateEnum
CREATE TYPE "StoreLocationType" AS ENUM ('CANTEEN', 'OUTDOOR');

-- CreateTable
CREATE TABLE "CampusCanteen" (
    "id" UUID NOT NULL,
    "campusCode" VARCHAR(32) NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CampusCanteen_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CanteenFloor" (
    "id" UUID NOT NULL,
    "canteenId" UUID NOT NULL,
    "floorOrder" INTEGER NOT NULL,
    "floorLabel" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CanteenFloor_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "CampusStore"
    ADD COLUMN "locationType" "StoreLocationType" NOT NULL DEFAULT 'OUTDOOR',
    ADD COLUMN "floorId" UUID;

-- CreateIndex
CREATE INDEX "CampusStore_campusCode_locationType_idx" ON "CampusStore"("campusCode", "locationType");

-- CreateIndex
CREATE INDEX "CampusStore_floorId_idx" ON "CampusStore"("floorId");

-- CreateIndex
CREATE INDEX "CampusCanteen_campusCode_idx" ON "CampusCanteen"("campusCode");

-- CreateIndex
CREATE UNIQUE INDEX "CampusCanteen_campusCode_name_key" ON "CampusCanteen"("campusCode", "name");

-- CreateIndex
CREATE INDEX "CanteenFloor_canteenId_idx" ON "CanteenFloor"("canteenId");

-- CreateIndex
CREATE INDEX "CanteenFloor_canteenId_floorOrder_idx" ON "CanteenFloor"("canteenId", "floorOrder");

-- CreateIndex
CREATE UNIQUE INDEX "CanteenFloor_canteenId_floorOrder_key" ON "CanteenFloor"("canteenId", "floorOrder");

-- CreateIndex
CREATE UNIQUE INDEX "CanteenFloor_canteenId_floorLabel_key" ON "CanteenFloor"("canteenId", "floorLabel");

-- AddForeignKey
ALTER TABLE "CampusCanteen"
    ADD CONSTRAINT "CampusCanteen_campusCode_fkey"
    FOREIGN KEY ("campusCode") REFERENCES "Campus"("code") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CanteenFloor"
    ADD CONSTRAINT "CanteenFloor_canteenId_fkey"
    FOREIGN KEY ("canteenId") REFERENCES "CampusCanteen"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CampusStore"
    ADD CONSTRAINT "CampusStore_floorId_fkey"
    FOREIGN KEY ("floorId") REFERENCES "CanteenFloor"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddCheckConstraint
ALTER TABLE "CampusStore"
    ADD CONSTRAINT "CampusStore_locationType_floorId_check"
    CHECK (
        (
            "locationType" = 'CANTEEN'::"StoreLocationType"
            AND "floorId" IS NOT NULL
        )
        OR (
            "locationType" = 'OUTDOOR'::"StoreLocationType"
            AND "floorId" IS NULL
        )
    );
