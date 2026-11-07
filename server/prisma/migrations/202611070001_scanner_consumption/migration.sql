-- CreateTable
CREATE TABLE `User` (
    `id` VARCHAR(36) NOT NULL,
    `email` VARCHAR(254) NOT NULL,
    `passwordHash` VARCHAR(255) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `User_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `NutritionProfile` (
    `userId` VARCHAR(36) NOT NULL,
    `name` VARCHAR(60) NOT NULL DEFAULT '',
    `age` INTEGER NULL,
    `heightCm` DOUBLE NULL,
    `weightKg` DOUBLE NULL,
    `preference` VARCHAR(32) NULL,
    `priorities` JSON NOT NULL,
    `eatingPattern` VARCHAR(16) NULL,
    `prefersHalal` BOOLEAN NOT NULL DEFAULT false,
    `allergyStatus` ENUM('unknown', 'noneKnown', 'listed') NOT NULL DEFAULT 'unknown',
    `allergies` JSON NOT NULL,
    `otherAllergies` VARCHAR(120) NOT NULL DEFAULT '',
    `audioAnalysisEnabled` BOOLEAN NOT NULL DEFAULT false,
    `timezone` VARCHAR(64) NOT NULL DEFAULT 'Asia/Jakarta',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`userId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `FoodEntry` (
    `id` VARCHAR(36) NOT NULL,
    `userId` VARCHAR(36) NOT NULL,
    `consumedAt` DATETIME(3) NOT NULL,
    `mode` VARCHAR(8) NOT NULL,
    `title` VARCHAR(160) NOT NULL,
    `description` TEXT NOT NULL,
    `rawOcrText` TEXT NULL,
    `quantity` DECIMAL(18, 6) NOT NULL,
    `baseQuantity` DECIMAL(18, 6) NOT NULL,
    `calories_kcal` DECIMAL(18, 6) NULL,
    `protein_g` DECIMAL(18, 6) NULL,
    `total_fat_g` DECIMAL(18, 6) NULL,
    `saturated_fat_g` DECIMAL(18, 6) NULL,
    `carbohydrates_g` DECIMAL(18, 6) NULL,
    `sugar_g` DECIMAL(18, 6) NULL,
    `sodium_mg` DECIMAL(18, 6) NULL,
    `fiber_g` DECIMAL(18, 6) NULL,
    `provenance` VARCHAR(32) NOT NULL,
    `analysis` JSON NOT NULL,
    `context` JSON NOT NULL,
    `model` VARCHAR(80) NOT NULL,
    `promptVersion` VARCHAR(40) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `FoodEntry_userId_consumedAt_id_idx`(`userId`, `consumedAt`, `id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `KnowledgeChunk` (
    `id` VARCHAR(80) NOT NULL,
    `title` VARCHAR(160) NOT NULL,
    `text` TEXT NOT NULL,
    `tags` JSON NOT NULL,
    `sourceUrl` VARCHAR(512) NOT NULL,
    `sourceTitle` VARCHAR(160) NOT NULL,
    `version` VARCHAR(40) NOT NULL,
    `reviewedAt` DATETIME(3) NULL,
    `reviewed` BOOLEAN NOT NULL DEFAULT false,
    `license` VARCHAR(255) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ScanRequest` (
    `id` VARCHAR(36) NOT NULL,
    `userId` VARCHAR(36) NOT NULL,
    `key` VARCHAR(36) NOT NULL,
    `fingerprint` VARCHAR(64) NOT NULL,
    `state` ENUM('processing', 'dispatched', 'completed', 'failed', 'deleted') NOT NULL DEFAULT 'processing',
    `dispatchedAt` DATETIME(3) NULL,
    `entryId` VARCHAR(36) NULL,
    `errorCode` VARCHAR(64) NULL,
    `errorStatus` INTEGER NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `ScanRequest_entryId_key`(`entryId`),
    UNIQUE INDEX `ScanRequest_userId_key_key`(`userId`, `key`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `NutritionProfile` ADD CONSTRAINT `NutritionProfile_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `FoodEntry` ADD CONSTRAINT `FoodEntry_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ScanRequest` ADD CONSTRAINT `ScanRequest_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ScanRequest` ADD CONSTRAINT `ScanRequest_entryId_fkey` FOREIGN KEY (`entryId`) REFERENCES `FoodEntry`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
