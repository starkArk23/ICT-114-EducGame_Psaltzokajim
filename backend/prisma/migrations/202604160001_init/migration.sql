-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "ThreatType" AS ENUM ('PHISHING', 'MALWARE', 'SOCIAL_ENGINEERING', 'PASSWORD_ATTACK', 'DATA_BREACH', 'RANSOMWARE', 'SCAM', 'UNSAFE_DOWNLOAD');

-- CreateEnum
CREATE TYPE "DifficultyLevel" AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED');

-- CreateEnum
CREATE TYPE "EncounterType" AS ENUM ('RANDOM_ENCOUNTER', 'ZONE_SPECIFIC', 'SCRIPTED');

-- CreateEnum
CREATE TYPE "AttemptOutcome" AS ENUM ('SUCCESS', 'FAILURE');

-- CreateEnum
CREATE TYPE "LedgerEntryReason" AS ENUM ('CHOICE_OUTCOME', 'SAVE_LOAD', 'REPORT_GENERATED', 'ADMIN_ADJUSTMENT');

-- CreateEnum
CREATE TYPE "ReportType" AS ENUM ('SESSION_SUMMARY', 'LEARNING_OUTCOME', 'SECURITY_ASSESSMENT');

-- CreateEnum
CREATE TYPE "AuditActorRole" AS ENUM ('PLAYER', 'ADMIN', 'SYSTEM');

-- CreateTable
CREATE TABLE "Player" (
    "id" TEXT NOT NULL,
    "operatorName" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Player_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SaveSlot" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "slotNumber" INTEGER NOT NULL,
    "slotName" TEXT,
    "currentScenarioId" TEXT,
    "currentScene" TEXT,
    "currentLocation" TEXT,
    "currentCyberStatus" INTEGER NOT NULL DEFAULT 50,
    "currentTrustTokens" INTEGER NOT NULL DEFAULT 0,
    "unlockedFlags" JSONB NOT NULL DEFAULT '[]',
    "sessionState" JSONB NOT NULL DEFAULT '{}',
    "totalAttempts" INTEGER NOT NULL DEFAULT 0,
    "successfulAttempts" INTEGER NOT NULL DEFAULT 0,
    "lastPlayedAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SaveSlot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ThreatScenario" (
    "id" TEXT NOT NULL,
    "externalKey" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "promptText" TEXT NOT NULL,
    "threatType" "ThreatType" NOT NULL,
    "difficultyLevel" "DifficultyLevel" NOT NULL,
    "encounterType" "EncounterType" NOT NULL DEFAULT 'RANDOM_ENCOUNTER',
    "educationalObjective" TEXT,
    "narrativeContext" TEXT,
    "recommendedOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isRepeatable" BOOLEAN NOT NULL DEFAULT true,
    "cooldownSeconds" INTEGER NOT NULL DEFAULT 0,
    "requiredFlags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ThreatScenario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ThreatChoice" (
    "id" TEXT NOT NULL,
    "scenarioId" TEXT NOT NULL,
    "choiceIndex" INTEGER NOT NULL,
    "choiceText" TEXT NOT NULL,
    "feedbackText" TEXT NOT NULL,
    "outcomeText" TEXT NOT NULL,
    "isCorrect" BOOLEAN NOT NULL,
    "trustTokenDelta" INTEGER NOT NULL DEFAULT 0,
    "cyberStatusDelta" INTEGER NOT NULL DEFAULT 0,
    "setsFlags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ThreatChoice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventPool" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "triggerZone" TEXT,
    "encounterType" "EncounterType" NOT NULL DEFAULT 'RANDOM_ENCOUNTER',
    "frequency" DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EventPool_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventPoolScenario" (
    "eventPoolId" TEXT NOT NULL,
    "scenarioId" TEXT NOT NULL,
    "weight" DECIMAL(5,2) NOT NULL DEFAULT 1.0,

    CONSTRAINT "EventPoolScenario_pkey" PRIMARY KEY ("eventPoolId","scenarioId")
);

-- CreateTable
CREATE TABLE "ScenarioAttempt" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "saveSlotId" TEXT NOT NULL,
    "scenarioId" TEXT NOT NULL,
    "selectedChoiceId" TEXT NOT NULL,
    "outcome" "AttemptOutcome" NOT NULL,
    "wasCorrect" BOOLEAN NOT NULL,
    "trustTokenDelta" INTEGER NOT NULL DEFAULT 0,
    "cyberStatusDelta" INTEGER NOT NULL DEFAULT 0,
    "choiceSnapshot" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ScenarioAttempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrustTokenLedger" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "saveSlotId" TEXT NOT NULL,
    "scenarioAttemptId" TEXT,
    "delta" INTEGER NOT NULL,
    "resultingValue" INTEGER NOT NULL,
    "reason" "LedgerEntryReason" NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TrustTokenLedger_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CyberStatusLedger" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "saveSlotId" TEXT NOT NULL,
    "scenarioAttemptId" TEXT,
    "delta" INTEGER NOT NULL,
    "resultingValue" INTEGER NOT NULL,
    "reason" "LedgerEntryReason" NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CyberStatusLedger_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProgressSummary" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "saveSlotId" TEXT NOT NULL,
    "scenariosCompleted" INTEGER NOT NULL DEFAULT 0,
    "totalAttempts" INTEGER NOT NULL DEFAULT 0,
    "successfulAttempts" INTEGER NOT NULL DEFAULT 0,
    "failedAttempts" INTEGER NOT NULL DEFAULT 0,
    "currentAccuracy" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProgressSummary_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SecurityReport" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "saveSlotId" TEXT NOT NULL,
    "reportType" "ReportType" NOT NULL,
    "summary" TEXT NOT NULL,
    "detailedJson" JSONB NOT NULL,
    "strengths" JSONB NOT NULL,
    "improvementAreas" JSONB NOT NULL,
    "finalCyberStatus" INTEGER NOT NULL,
    "finalTrustTokens" INTEGER NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SecurityReport_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "playerId" TEXT,
    "saveSlotId" TEXT,
    "actorRole" "AuditActorRole" NOT NULL,
    "action" TEXT NOT NULL,
    "payload" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Player_operatorName_key" ON "Player"("operatorName");

-- CreateIndex
CREATE INDEX "Player_operatorName_idx" ON "Player"("operatorName");

-- CreateIndex
CREATE INDEX "SaveSlot_playerId_slotNumber_idx" ON "SaveSlot"("playerId", "slotNumber");

-- CreateIndex
CREATE INDEX "SaveSlot_lastPlayedAt_idx" ON "SaveSlot"("lastPlayedAt");

-- CreateIndex
CREATE UNIQUE INDEX "SaveSlot_playerId_slotNumber_key" ON "SaveSlot"("playerId", "slotNumber");

-- CreateIndex
CREATE UNIQUE INDEX "ThreatScenario_externalKey_key" ON "ThreatScenario"("externalKey");

-- CreateIndex
CREATE INDEX "ThreatScenario_threatType_difficultyLevel_idx" ON "ThreatScenario"("threatType", "difficultyLevel");

-- CreateIndex
CREATE INDEX "ThreatScenario_isActive_recommendedOrder_idx" ON "ThreatScenario"("isActive", "recommendedOrder");

-- CreateIndex
CREATE UNIQUE INDEX "ThreatChoice_scenarioId_choiceIndex_key" ON "ThreatChoice"("scenarioId", "choiceIndex");

-- CreateIndex
CREATE UNIQUE INDEX "EventPool_name_key" ON "EventPool"("name");

-- CreateIndex
CREATE INDEX "ScenarioAttempt_playerId_createdAt_idx" ON "ScenarioAttempt"("playerId", "createdAt");

-- CreateIndex
CREATE INDEX "ScenarioAttempt_saveSlotId_createdAt_idx" ON "ScenarioAttempt"("saveSlotId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "TrustTokenLedger_scenarioAttemptId_key" ON "TrustTokenLedger"("scenarioAttemptId");

-- CreateIndex
CREATE INDEX "TrustTokenLedger_playerId_createdAt_idx" ON "TrustTokenLedger"("playerId", "createdAt");

-- CreateIndex
CREATE INDEX "TrustTokenLedger_saveSlotId_createdAt_idx" ON "TrustTokenLedger"("saveSlotId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CyberStatusLedger_scenarioAttemptId_key" ON "CyberStatusLedger"("scenarioAttemptId");

-- CreateIndex
CREATE INDEX "CyberStatusLedger_playerId_createdAt_idx" ON "CyberStatusLedger"("playerId", "createdAt");

-- CreateIndex
CREATE INDEX "CyberStatusLedger_saveSlotId_createdAt_idx" ON "CyberStatusLedger"("saveSlotId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "ProgressSummary_saveSlotId_key" ON "ProgressSummary"("saveSlotId");

-- CreateIndex
CREATE INDEX "SecurityReport_playerId_generatedAt_idx" ON "SecurityReport"("playerId", "generatedAt");

-- CreateIndex
CREATE INDEX "SecurityReport_saveSlotId_generatedAt_idx" ON "SecurityReport"("saveSlotId", "generatedAt");

-- CreateIndex
CREATE INDEX "AuditLog_playerId_createdAt_idx" ON "AuditLog"("playerId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_saveSlotId_createdAt_idx" ON "AuditLog"("saveSlotId", "createdAt");

-- AddForeignKey
ALTER TABLE "SaveSlot" ADD CONSTRAINT "SaveSlot_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SaveSlot" ADD CONSTRAINT "SaveSlot_currentScenarioId_fkey" FOREIGN KEY ("currentScenarioId") REFERENCES "ThreatScenario"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ThreatChoice" ADD CONSTRAINT "ThreatChoice_scenarioId_fkey" FOREIGN KEY ("scenarioId") REFERENCES "ThreatScenario"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventPoolScenario" ADD CONSTRAINT "EventPoolScenario_eventPoolId_fkey" FOREIGN KEY ("eventPoolId") REFERENCES "EventPool"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventPoolScenario" ADD CONSTRAINT "EventPoolScenario_scenarioId_fkey" FOREIGN KEY ("scenarioId") REFERENCES "ThreatScenario"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScenarioAttempt" ADD CONSTRAINT "ScenarioAttempt_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScenarioAttempt" ADD CONSTRAINT "ScenarioAttempt_saveSlotId_fkey" FOREIGN KEY ("saveSlotId") REFERENCES "SaveSlot"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScenarioAttempt" ADD CONSTRAINT "ScenarioAttempt_scenarioId_fkey" FOREIGN KEY ("scenarioId") REFERENCES "ThreatScenario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScenarioAttempt" ADD CONSTRAINT "ScenarioAttempt_selectedChoiceId_fkey" FOREIGN KEY ("selectedChoiceId") REFERENCES "ThreatChoice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrustTokenLedger" ADD CONSTRAINT "TrustTokenLedger_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrustTokenLedger" ADD CONSTRAINT "TrustTokenLedger_saveSlotId_fkey" FOREIGN KEY ("saveSlotId") REFERENCES "SaveSlot"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrustTokenLedger" ADD CONSTRAINT "TrustTokenLedger_scenarioAttemptId_fkey" FOREIGN KEY ("scenarioAttemptId") REFERENCES "ScenarioAttempt"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CyberStatusLedger" ADD CONSTRAINT "CyberStatusLedger_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CyberStatusLedger" ADD CONSTRAINT "CyberStatusLedger_saveSlotId_fkey" FOREIGN KEY ("saveSlotId") REFERENCES "SaveSlot"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CyberStatusLedger" ADD CONSTRAINT "CyberStatusLedger_scenarioAttemptId_fkey" FOREIGN KEY ("scenarioAttemptId") REFERENCES "ScenarioAttempt"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProgressSummary" ADD CONSTRAINT "ProgressSummary_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProgressSummary" ADD CONSTRAINT "ProgressSummary_saveSlotId_fkey" FOREIGN KEY ("saveSlotId") REFERENCES "SaveSlot"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SecurityReport" ADD CONSTRAINT "SecurityReport_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SecurityReport" ADD CONSTRAINT "SecurityReport_saveSlotId_fkey" FOREIGN KEY ("saveSlotId") REFERENCES "SaveSlot"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_saveSlotId_fkey" FOREIGN KEY ("saveSlotId") REFERENCES "SaveSlot"("id") ON DELETE SET NULL ON UPDATE CASCADE;

