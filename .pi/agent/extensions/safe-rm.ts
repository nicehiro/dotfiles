// From: https://github.com/qualisero/rhubarb-pi/tree/main/extensions/safe-rm

/**
 * Safe-RM Extension
 *
 * Intercepts rm commands and replaces them with macOS `trash` command.
 * Logs both original and replacement commands to debug log file.
 * Carefully detects rm to avoid false positives.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

interface SafeRmConfig {
  enabledByDefault?: boolean;
  debugLogPath?: string;
}

const DEFAULT_CONFIG: Required<SafeRmConfig> = {
  enabledByDefault: true,
  debugLogPath: path.join(os.homedir(), '.pi', 'safe-rm-debug.log'),
};

export default function (pi: ExtensionAPI) {
  let sessionEnabledOverride: boolean | null = null;

  function getEffectiveConfig(ctx: any): { enabled: boolean; debugLogPath: string } {
    const settings = ctx.settingsManager?.getSettings() ?? {};
    const config: Required<SafeRmConfig> = {
      ...DEFAULT_CONFIG,
      ...(settings.safeRm ?? {}),
    };

    const enabled = sessionEnabledOverride !== null
      ? sessionEnabledOverride
      : config.enabledByDefault;

    return { enabled, debugLogPath: config.debugLogPath };
  }

  function isRmCommand(command: string): boolean {
    const trimmed = command.trim();
    const rmPatterns = [
      /^(?:\/[\w\/]+\/)?rm\b/,
    ];

    for (const pattern of rmPatterns) {
      if (pattern.test(trimmed)) {
        return true;
      }
    }

    return false;
  }

  function parseRmCommand(command: string): { flags: string; files: string[]; commandRest: string } {
    const trimmed = command.trim();
    const withoutRm = trimmed.replace(/^(?:\/[\w\/]+\/)?rm\b\s*/, '');
    const parts = withoutRm.split(/\s+/).filter(p => p.length > 0);

    const flags: string[] = [];
    const files: string[] = [];

    for (const part of parts) {
      if (part.startsWith('-')) {
        flags.push(part);
      } else {
        files.push(part);
      }
    }

    return {
      flags: flags.join(' '),
      files,
      commandRest: withoutRm,
    };
  }

  function buildTrashCommand(files: string[]): string {
    const isMacOS = os.platform() === 'darwin';

    if (isMacOS) {
      const quotedFiles = files.map(f => `'${f.replace(/'/g, "'\\''")}'`);
      return `trash ${quotedFiles.join(' ')}`;
    }

    return `rm ${files.map(f => `'${f.replace(/'/g, "'\\''")}'`).join(' ')}`;
  }

  function logToDebugFile(logPath: string, originalCmd: string, trashCmd: string, files: string[]) {
    const timestamp = new Date().toISOString();
    const entry = `[${timestamp}] | ${originalCmd} → trash\n`;

    try {
      const logDir = path.dirname(logPath);
      if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
      }
      fs.appendFileSync(logPath, entry, 'utf8');
    } catch (e) {
      console.error(`[safe-rm] Failed to write debug log: ${e}`);
    }
  }

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== 'bash') return undefined;

    const command = event.input.command as string;

    if (!isRmCommand(command)) return undefined;

    const { enabled, debugLogPath } = getEffectiveConfig(ctx);

    if (!enabled) return undefined;

    const { files } = parseRmCommand(command);

    if (files.length === 0) {
      return undefined;
    }

    const trashCmd = buildTrashCommand(files);

    logToDebugFile(debugLogPath, command, trashCmd, files);

    return {
      command: trashCmd,
      reason: `safe-rm: Replaced 'rm' with 'trash' for ${files.length} file(s)`,
    };
  });

  pi.registerCommand("saferm", {
    description: "Show safe-rm status",
    handler: async (args, ctx) => {
      const { enabled, debugLogPath } = getEffectiveConfig(ctx);
      const status = enabled ? "🟢 ON" : "🔴 OFF";

      let logInfo = "";
      try {
        if (fs.existsSync(debugLogPath)) {
          const stats = fs.statSync(debugLogPath);
          const sizeKB = (stats.size / 1024).toFixed(1);
          logInfo = `\n📜 Debug log: ${debugLogPath} (${sizeKB} KB)`;
        }
      } catch (e) {
        logInfo = "\n⚠️  Could not read debug log";
      }

      const isMacOS = os.platform() === 'darwin';
      const osInfo = isMacOS ? "macOS: trash command" : "Non-macOS: falls back to rm";

      ctx.ui?.notify?.([
        "╭─ Safe-RM Status ─╮",
        `│                     │`,
        `│  Status: ${status} │`,
        `│  ${osInfo.padEnd(15)} │`,
        `${logInfo}`,
        `│                     │`,
        `╰─────────────────────╯`,
        "",
        "Commands:",
        "  /saferm-on   - Enable",
        "  /saferm-off  - Disable",
        "  /saferm-toggle - Toggle",
        "  /saferm-log - View log",
        "  /saferm-clearlog - Clear log",
        "",
        "All rm commands are logged to:",
        `  ${debugLogPath}`,
      ].join('\n'), 'info');
    },
  });

  pi.registerCommand("saferm-toggle", {
    description: "Toggle safe-rm on/off",
    handler: async (args, ctx) => {
      const { enabled } = getEffectiveConfig(ctx);
      sessionEnabledOverride = !enabled;
      ctx.ui?.notify?.(sessionEnabledOverride ? "🟢 Safe-RM: ON" : "🔴 Safe-RM: OFF", 'info');
    },
  });

  pi.registerCommand("saferm-on", {
    description: "Enable safe-rm",
    handler: async (args, ctx) => {
      sessionEnabledOverride = true;
      ctx.ui?.notify?.("🟢 Safe-RM: ON", 'info');
    },
  });

  pi.registerCommand("saferm-off", {
    description: "Disable safe-rm",
    handler: async (args, ctx) => {
      sessionEnabledOverride = false;
      ctx.ui?.notify?.("🔴 Safe-RM: OFF", 'info');
    },
  });

  pi.registerCommand("saferm-log", {
    description: "Show debug log contents",
    handler: async (args, ctx) => {
      const { debugLogPath } = getEffectiveConfig(ctx);

      try {
        if (!fs.existsSync(debugLogPath)) {
          ctx.ui?.notify?.("No debug log found yet.", 'info');
          return;
        }

        const content = fs.readFileSync(debugLogPath, 'utf8');
        const lines = content.trim().split('\n');
        const last20 = lines.slice(-20);

        ctx.ui?.notify?.([
          "╭─ Safe-RM Debug Log (last 20) ─╮",
          `│                                    │`,
          ...last20.map(line => `│ ${line.slice(0, 75)}${line.length > 75 ? '...' : ''} │`),
          `│                                    │`,
          `╰────────────────────────────────────╯`,
          "",
          `Full log: ${debugLogPath}`,
        ].join('\n'), 'info');
      } catch (e) {
        ctx.ui?.notify?.(`Error reading log: ${e}`, 'warning');
      }
    },
  });

  pi.registerCommand("saferm-clearlog", {
    description: "Clear debug log file",
    handler: async (args, ctx) => {
      const { debugLogPath } = getEffectiveConfig(ctx);

      try {
        if (fs.existsSync(debugLogPath)) {
          fs.unlinkSync(debugLogPath);
          ctx.ui?.notify?.("🗑️  Debug log cleared.", 'info');
        } else {
          ctx.ui?.notify?.("No debug log to clear.", 'info');
        }
      } catch (e) {
        ctx.ui?.notify?.(`Error clearing log: ${e}`, 'warning');
      }
    },
  });
}
