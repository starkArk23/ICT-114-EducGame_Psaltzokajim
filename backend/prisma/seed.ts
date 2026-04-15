import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { DifficultyLevel, EncounterType, PrismaClient, ThreatType } from "@prisma/client";

const prisma = new PrismaClient();
const currentDirectory = dirname(fileURLToPath(import.meta.url));

type SeedData = {
  eventPools: Array<{
    name: string;
    triggerZone: string | null;
    encounterType: EncounterType;
    frequency: number;
    scenarioKeys: Array<{ key: string; weight: number }>;
  }>;
  scenarios: Array<{
    externalKey: string;
    title: string;
    summary: string;
    promptText: string;
    threatType: string;
    difficultyLevel: string;
    encounterType: EncounterType;
    educationalObjective?: string;
    narrativeContext?: string;
    recommendedOrder: number;
    isRepeatable: boolean;
    cooldownSeconds: number;
    requiredFlags: string[];
    choices: Array<{
      choiceIndex: number;
      choiceText: string;
      feedbackText: string;
      outcomeText: string;
      isCorrect: boolean;
      trustTokenDelta: number;
      cyberStatusDelta: number;
      setsFlags: string[];
    }>;
  }>;
};

async function loadSeedData() {
  const seedPath = join(currentDirectory, "seed-data", "threat-scenarios.json");
  const json = await readFile(seedPath, "utf8");
  return JSON.parse(json) as SeedData;
}

async function upsertScenario(seedData: SeedData, scenario: SeedData["scenarios"][number]) {
  const persistedScenario = await prisma.threatScenario.upsert({
    where: { externalKey: scenario.externalKey },
    update: {
      title: scenario.title,
      summary: scenario.summary,
      promptText: scenario.promptText,
      threatType: scenario.threatType as ThreatType,
      difficultyLevel: scenario.difficultyLevel as DifficultyLevel,
      encounterType: scenario.encounterType,
      educationalObjective: scenario.educationalObjective,
      narrativeContext: scenario.narrativeContext,
      recommendedOrder: scenario.recommendedOrder,
      isRepeatable: scenario.isRepeatable,
      cooldownSeconds: scenario.cooldownSeconds,
      requiredFlags: scenario.requiredFlags,
      isActive: true
    },
    create: {
      externalKey: scenario.externalKey,
      title: scenario.title,
      summary: scenario.summary,
      promptText: scenario.promptText,
      threatType: scenario.threatType as ThreatType,
      difficultyLevel: scenario.difficultyLevel as DifficultyLevel,
      encounterType: scenario.encounterType,
      educationalObjective: scenario.educationalObjective,
      narrativeContext: scenario.narrativeContext,
      recommendedOrder: scenario.recommendedOrder,
      isRepeatable: scenario.isRepeatable,
      cooldownSeconds: scenario.cooldownSeconds,
      requiredFlags: scenario.requiredFlags,
      isActive: true
    }
  });

  for (const choice of scenario.choices) {
    await prisma.threatChoice.upsert({
      where: {
        scenarioId_choiceIndex: {
          scenarioId: persistedScenario.id,
          choiceIndex: choice.choiceIndex
        }
      },
      update: {
        choiceText: choice.choiceText,
        feedbackText: choice.feedbackText,
        outcomeText: choice.outcomeText,
        isCorrect: choice.isCorrect,
        trustTokenDelta: choice.trustTokenDelta,
        cyberStatusDelta: choice.cyberStatusDelta,
        setsFlags: choice.setsFlags
      },
      create: {
        scenarioId: persistedScenario.id,
        choiceIndex: choice.choiceIndex,
        choiceText: choice.choiceText,
        feedbackText: choice.feedbackText,
        outcomeText: choice.outcomeText,
        isCorrect: choice.isCorrect,
        trustTokenDelta: choice.trustTokenDelta,
        cyberStatusDelta: choice.cyberStatusDelta,
        setsFlags: choice.setsFlags
      }
    });
  }

  return persistedScenario.id;
}

async function main() {
  const seedData = await loadSeedData();
  const scenarioIdByKey = new Map<string, string>();

  for (const scenario of seedData.scenarios) {
    const scenarioId = await upsertScenario(seedData, scenario);
    scenarioIdByKey.set(scenario.externalKey, scenarioId);
  }

  for (const eventPool of seedData.eventPools) {
    const persistedEventPool = await prisma.eventPool.upsert({
      where: { name: eventPool.name },
      update: {
        triggerZone: eventPool.triggerZone ?? undefined,
        encounterType: eventPool.encounterType,
        frequency: eventPool.frequency,
        isActive: true
      },
      create: {
        name: eventPool.name,
        triggerZone: eventPool.triggerZone ?? undefined,
        encounterType: eventPool.encounterType,
        frequency: eventPool.frequency,
        isActive: true
      }
    });

    for (const link of eventPool.scenarioKeys) {
      const scenarioId = scenarioIdByKey.get(link.key);

      if (!scenarioId) {
        continue;
      }

      await prisma.eventPoolScenario.upsert({
        where: {
          eventPoolId_scenarioId: {
            eventPoolId: persistedEventPool.id,
            scenarioId
          }
        },
        update: {
          weight: link.weight
        },
        create: {
          eventPoolId: persistedEventPool.id,
          scenarioId,
          weight: link.weight
        }
      });
    }
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });