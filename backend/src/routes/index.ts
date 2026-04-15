import { Router } from "express";
import { ThreatType } from "@prisma/client";

import { recordScenarioAttempt } from "../services/attempt-service.js";
import { createPlayer, createSaveSlot, getSaveSlot, listSaveSlots } from "../services/player-service.js";
import { generateSecurityReport } from "../services/report-service.js";
import { getRandomScenario } from "../services/scenario-service.js";

export const apiRouter = Router();

apiRouter.get("/health", (_request, response) => {
  response.json({ ok: true });
});

apiRouter.post("/players", async (request, response, next) => {
  try {
    const operatorName = String(request.body?.operatorName ?? "").trim();

    if (!operatorName) {
      response.status(400).json({ message: "operatorName is required." });
      return;
    }

    const player = await createPlayer(operatorName);
    response.status(201).json(player);
  } catch (error) {
    next(error);
  }
});

apiRouter.get("/players/:playerId/save-slots", async (request, response, next) => {
  try {
    const saveSlots = await listSaveSlots(request.params.playerId);
    response.json(saveSlots);
  } catch (error) {
    next(error);
  }
});

apiRouter.post("/players/:playerId/save-slots", async (request, response, next) => {
  try {
    const slotNumber = Number(request.body?.slotNumber);

    if (!Number.isInteger(slotNumber) || slotNumber < 1) {
      response.status(400).json({ message: "slotNumber must be a positive integer." });
      return;
    }

    const saveSlot = await createSaveSlot(
      request.params.playerId,
      slotNumber,
      typeof request.body?.slotName === "string" ? request.body.slotName : undefined
    );

    response.status(201).json(saveSlot);
  } catch (error) {
    next(error);
  }
});

apiRouter.get("/save-slots/:saveSlotId", async (request, response, next) => {
  try {
    const saveSlot = await getSaveSlot(request.params.saveSlotId);

    if (!saveSlot) {
      response.status(404).json({ message: "Save slot not found." });
      return;
    }

    response.json(saveSlot);
  } catch (error) {
    next(error);
  }
});

apiRouter.get("/scenarios/random", async (request, response, next) => {
  try {
    const saveSlotId = typeof request.query.saveSlotId === "string" ? request.query.saveSlotId : undefined;
    const rawThreatType = typeof request.query.threatType === "string" ? request.query.threatType.toUpperCase() : undefined;
    const threatType = rawThreatType && rawThreatType in ThreatType ? (rawThreatType as ThreatType) : undefined;
    const scenario = await getRandomScenario(saveSlotId, threatType);

    if (!scenario) {
      response.status(404).json({ message: "No matching scenario found." });
      return;
    }

    response.json(scenario);
  } catch (error) {
    next(error);
  }
});

apiRouter.post("/attempts", async (request, response, next) => {
  try {
    const attempt = await recordScenarioAttempt({
      saveSlotId: String(request.body?.saveSlotId ?? ""),
      scenarioId: String(request.body?.scenarioId ?? ""),
      selectedChoiceId: String(request.body?.selectedChoiceId ?? "")
    });

    response.status(201).json(attempt);
  } catch (error) {
    next(error);
  }
});

apiRouter.post("/reports", async (request, response, next) => {
  try {
    const report = await generateSecurityReport(String(request.body?.saveSlotId ?? ""));
    response.status(201).json(report);
  } catch (error) {
    next(error);
  }
});