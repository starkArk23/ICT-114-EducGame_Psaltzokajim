import { LedgerEntryReason, Prisma } from "@prisma/client";

import { prisma } from "../lib/prisma.js";

type RecordAttemptInput = {
  saveSlotId: string;
  scenarioId: string;
  selectedChoiceId: string;
};

export async function recordScenarioAttempt(input: RecordAttemptInput) {
  const choice = await prisma.threatChoice.findUnique({
    where: { id: input.selectedChoiceId },
    include: { scenario: true }
  });

  if (!choice || choice.scenarioId !== input.scenarioId) {
    throw new Error("Selected choice does not belong to the scenario.");
  }

  const saveSlot = await prisma.saveSlot.findUnique({
    where: { id: input.saveSlotId },
    include: { player: true }
  });

  if (!saveSlot) {
    throw new Error("Save slot not found.");
  }

  const nextCyberStatus = Math.max(0, Math.min(100, saveSlot.currentCyberStatus + choice.cyberStatusDelta));
  const nextTrustTokens = Math.max(0, saveSlot.currentTrustTokens + choice.trustTokenDelta);
  const currentFlags = Array.isArray(saveSlot.unlockedFlags) ? (saveSlot.unlockedFlags as string[]) : [];
  const nextFlags = Array.from(new Set([...currentFlags, ...choice.setsFlags]));

  return prisma.$transaction(async (tx: Prisma.TransactionClient) => {
    const attempt = await tx.scenarioAttempt.create({
      data: {
        playerId: saveSlot.playerId,
        saveSlotId: saveSlot.id,
        scenarioId: input.scenarioId,
        selectedChoiceId: input.selectedChoiceId,
        outcome: choice.isCorrect ? "SUCCESS" : "FAILURE",
        wasCorrect: choice.isCorrect,
        trustTokenDelta: choice.trustTokenDelta,
        cyberStatusDelta: choice.cyberStatusDelta,
        choiceSnapshot: {
          choiceText: choice.choiceText,
          feedbackText: choice.feedbackText,
          outcomeText: choice.outcomeText
        }
      }
    });

    await tx.trustTokenLedger.create({
      data: {
        playerId: saveSlot.playerId,
        saveSlotId: saveSlot.id,
        scenarioAttemptId: attempt.id,
        delta: choice.trustTokenDelta,
        resultingValue: nextTrustTokens,
        reason: LedgerEntryReason.CHOICE_OUTCOME,
        metadata: {
          scenarioId: input.scenarioId,
          choiceId: input.selectedChoiceId
        }
      }
    });

    await tx.cyberStatusLedger.create({
      data: {
        playerId: saveSlot.playerId,
        saveSlotId: saveSlot.id,
        scenarioAttemptId: attempt.id,
        delta: choice.cyberStatusDelta,
        resultingValue: nextCyberStatus,
        reason: LedgerEntryReason.CHOICE_OUTCOME,
        metadata: {
          scenarioId: input.scenarioId,
          choiceId: input.selectedChoiceId
        }
      }
    });

    const progress = await tx.progressSummary.upsert({
      where: { saveSlotId: saveSlot.id },
      update: {},
      create: {
        playerId: saveSlot.playerId,
        saveSlotId: saveSlot.id
      }
    });

    const totalAttempts = progress.totalAttempts + 1;
    const successfulAttempts = progress.successfulAttempts + (choice.isCorrect ? 1 : 0);
    const failedAttempts = totalAttempts - successfulAttempts;

    await tx.progressSummary.update({
      where: { id: progress.id },
      data: {
        totalAttempts,
        successfulAttempts,
        failedAttempts,
        currentAccuracy: new Prisma.Decimal((successfulAttempts / totalAttempts) * 100),
        scenariosCompleted: { increment: 1 }
      }
    });

    await tx.saveSlot.update({
      where: { id: saveSlot.id },
      data: {
        currentCyberStatus: nextCyberStatus,
        currentTrustTokens: nextTrustTokens,
        unlockedFlags: nextFlags,
        totalAttempts: { increment: 1 },
        successfulAttempts: choice.isCorrect ? { increment: 1 } : undefined,
        currentScenarioId: null,
        sessionState: {
          lastScenarioId: input.scenarioId,
          lastChoiceId: input.selectedChoiceId
        }
      }
    });

    return attempt;
  });
}