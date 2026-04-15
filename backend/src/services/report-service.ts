import { ReportType } from "@prisma/client";

import { prisma } from "../lib/prisma.js";

export async function generateSecurityReport(saveSlotId: string) {
  const saveSlot = await prisma.saveSlot.findUnique({
    where: { id: saveSlotId },
    include: {
      player: true,
      progressSummary: true,
      attempts: {
        include: {
          scenario: true,
          selectedChoice: true
        },
        orderBy: { createdAt: "asc" }
      }
    }
  });

  if (!saveSlot) {
    throw new Error("Save slot not found.");
  }

  const strengths = saveSlot.attempts
    .filter((attempt: (typeof saveSlot.attempts)[number]) => attempt.wasCorrect)
    .map((attempt: (typeof saveSlot.attempts)[number]) => attempt.scenario.title)
    .slice(0, 5);

  const improvementAreas = saveSlot.attempts
    .filter((attempt: (typeof saveSlot.attempts)[number]) => !attempt.wasCorrect)
    .map((attempt: (typeof saveSlot.attempts)[number]) => attempt.scenario.title)
    .slice(0, 5);

  const summary = `${saveSlot.player.operatorName} completed ${saveSlot.totalAttempts} threat responses with ${saveSlot.currentTrustTokens} trust tokens and cyber status ${saveSlot.currentCyberStatus}.`;

  return prisma.securityReport.create({
    data: {
      playerId: saveSlot.playerId,
      saveSlotId: saveSlot.id,
      reportType: ReportType.SESSION_SUMMARY,
      summary,
      detailedJson: {
        attempts: saveSlot.attempts.map((attempt: (typeof saveSlot.attempts)[number]) => ({
          scenarioTitle: attempt.scenario.title,
          selectedChoice: attempt.selectedChoice.choiceText,
          wasCorrect: attempt.wasCorrect,
          trustTokenDelta: attempt.trustTokenDelta,
          cyberStatusDelta: attempt.cyberStatusDelta,
          createdAt: attempt.createdAt
        })),
        progress: saveSlot.progressSummary
      },
      strengths,
      improvementAreas,
      finalCyberStatus: saveSlot.currentCyberStatus,
      finalTrustTokens: saveSlot.currentTrustTokens
    }
  });
}