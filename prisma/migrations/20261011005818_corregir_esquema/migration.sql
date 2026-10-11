/*
  Warnings:

  - The `status` column on the `Booking` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `plan` column on the `Membership` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to alter the column `pricePerHour` on the `Space` table. The data in that column could be lost. The data in that column will be cast from `Integer` to `Decimal(10,2)`.
  - The `role` column on the `User` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - Changed the type of `totalPrice` on the `Booking` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `location` to the `Space` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `type` on the `Space` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "Role" AS ENUM ('MEMBER', 'ADMIN');

-- CreateEnum
CREATE TYPE "SpaceType" AS ENUM ('INDIVIDUAL_DESK', 'PRIVATE_ROOM', 'ENTERPRISE_SUITE');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "MembershipPlan" AS ENUM ('BASIC', 'PRO', 'ENTERPRISE');

-- DropForeignKey
ALTER TABLE "Membership" DROP CONSTRAINT "Membership_userId_fkey";

-- AlterTable
ALTER TABLE "Booking" DROP COLUMN "status",
ADD COLUMN     "status" "BookingStatus" NOT NULL DEFAULT 'CONFIRMED',
DROP COLUMN "totalPrice",
ADD COLUMN     "totalPrice" DECIMAL(10,2) NOT NULL;

-- AlterTable
ALTER TABLE "Membership" DROP COLUMN "plan",
ADD COLUMN     "plan" "MembershipPlan" NOT NULL DEFAULT 'BASIC';

-- AlterTable
ALTER TABLE "Space" ADD COLUMN     "location" TEXT NOT NULL,
DROP COLUMN "type",
ADD COLUMN     "type" "SpaceType" NOT NULL,
ALTER COLUMN "pricePerHour" SET DATA TYPE DECIMAL(10,2);

-- AlterTable
ALTER TABLE "User" DROP COLUMN "role",
ADD COLUMN     "role" "Role" NOT NULL DEFAULT 'MEMBER';

-- CreateIndex
CREATE INDEX "Booking_spaceId_startTime_endTime_idx" ON "Booking"("spaceId", "startTime", "endTime");

-- CreateIndex
CREATE INDEX "Booking_userId_idx" ON "Booking"("userId");

-- CreateIndex
CREATE INDEX "Membership_endDate_idx" ON "Membership"("endDate");

-- CreateIndex
CREATE INDEX "Space_isActive_type_idx" ON "Space"("isActive", "type");

-- CreateIndex
CREATE INDEX "Space_location_idx" ON "Space"("location");

-- AddForeignKey
ALTER TABLE "Membership" ADD CONSTRAINT "Membership_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- Regla de negocio en la base: dos reservas activas no pueden solaparse en el mismo espacio
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE "Booking" ADD CONSTRAINT "booking_no_overlap"
  EXCLUDE USING gist ("spaceId" WITH =, tsrange("startTime", "endTime") WITH &&)
  WHERE ("status" <> 'CANCELLED');