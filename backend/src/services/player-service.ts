import { prisma } from "../lib/prisma.js";

export async function createPlayer(operatorName: string) {
  return prisma.player.create({
    data: {
      operatorName
    }
  });
}

export async function listSaveSlots(playerId: string) {
  return prisma.saveSlot.findMany({
    where: { playerId },
    orderBy: { slotNumber: "asc" },
    include: {
      currentScenario: true
    }
  });
}

export async function createSaveSlot(playerId: string, slotNumber: number, slotName?: string) {
  return prisma.saveSlot.create({
    data: {
      playerId,
      slotNumber,
      slotName,
      unlockedFlags: [],
      sessionState: {}
    }
  });
}

export async function getSaveSlot(saveSlotId: string) {
  return prisma.saveSlot.findUnique({
    where: { id: saveSlotId },
    include: {
      currentScenario: true,
      progressSummary: true,
      attempts: {
        orderBy: { createdAt: "desc" },
        take: 10,
        include: {
          scenario: true,
          selectedChoice: true
        }
      }
    }
  });
}