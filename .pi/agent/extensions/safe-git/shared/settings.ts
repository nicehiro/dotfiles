// From: https://github.com/qualisero/rhubarb-pi

import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { BackgroundNotifyConfig } from "./types";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";

const DEFAULT_CONFIG: BackgroundNotifyConfig = {
  thresholdMs: 2000,
  beep: true,
  beepSound: "Tink",
  bringToFront: true,
  say: false,
  sayMessage: "Task completed",
};

async function readSettingsFile(): Promise<any> {
  const settingsPath = path.join(os.homedir(), ".pi", "agent", "settings.json");
  try {
    const content = await fs.readFile(settingsPath, "utf8");
    return JSON.parse(content);
  } catch {
    return {};
  }
}

export async function getBackgroundNotifyConfig(
  ctx: ExtensionContext,
  overrides?: Partial<BackgroundNotifyConfig>
): Promise<BackgroundNotifyConfig> {
  const settings = (ctx as any).settingsManager?.getSettings() ?? {};

  let config: BackgroundNotifyConfig;

  if (settings.backgroundNotify) {
    config = { ...DEFAULT_CONFIG, ...settings.backgroundNotify };
  } else {
    const fileSettings = await readSettingsFile();
    config = { ...DEFAULT_CONFIG, ...fileSettings.backgroundNotify };
  }

  if (overrides) {
    config = { ...config, ...overrides };
  }

  return config;
}
