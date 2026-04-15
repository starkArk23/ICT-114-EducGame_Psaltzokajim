import { ThreatType } from "@prisma/client";

import { prisma } from "../lib/prisma.js";

export async function getRandomScenario(saveSlotId?: string, threatType?: ThreatType) {
  const saveSlot = saveSlotId
    ? await prisma.saveSlot.findUnique({
        where: { id: saveSlotId },
        select: { unlockedFlags: true }
      })
    : null;

  const unlockedFlags = Array.isArray(saveSlot?.unlockedFlags) ? (saveSlot.unlockedFlags as string[]) : [];

  const scenarios = await prisma.threatScenario.findMany({
    where: {
      isActive: true,
      ...(threatType ? { threatType } : {})
    },
    include: {
      choices: { orderBy: { choiceIndex: "asc" } }
    },
    orderBy: { recommendedOrder: "asc" }
  });

  const availableScenarios = scenarios.filter((scenario: (typeof scenarios)[number]) =>
    scenario.requiredFlags.every((flag: string) => unlockedFlags.includes(flag))
  );

  if (availableScenarios.length === 0) {
    return null;
  }

  const randomIndex = Math.floor(Math.random() * availableScenarios.length);

  return availableScenarios[randomIndex];
}