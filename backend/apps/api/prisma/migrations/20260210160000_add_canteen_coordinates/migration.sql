-- AlterTable
ALTER TABLE "CampusCanteen"
    ADD COLUMN "latitude" DECIMAL(9, 6),
    ADD COLUMN "longitude" DECIMAL(9, 6);

-- CreateIndex
CREATE INDEX "CampusCanteen_latitude_longitude_idx" ON "CampusCanteen"("latitude", "longitude");
