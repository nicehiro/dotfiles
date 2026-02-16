// From: https://github.com/qualisero/rhubarb-pi

import type { TerminalInfo, BackgroundNotifyConfig } from "./types";
import * as child_process from "node:child_process";
import { promisify } from "node:util";
import * as fs from "node:fs";
import * as fsPromises from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";

const execAsync = promisify(child_process.exec);

type PronunciationReplacements = Record<string, string>;

let pronunciationReplacements: PronunciationReplacements = {};
let pronunciationsLoaded = false;

async function parsePronunciationsPlist(
  plistPath: string
): Promise<PronunciationReplacements> {
  try {
    const content = await fsPromises.readFile(plistPath, "utf-8");
    const replacements: PronunciationReplacements = {};
    const keyRegex = /<key>([^<]+)<\/key>\s*<string>([^<]+)<\/string>/g;
    let match;
    while ((match = keyRegex.exec(content)) !== null) {
      const [, key, value] = match;
      replacements[key.trim()] = value.trim();
    }
    return replacements;
  } catch {
    return {};
  }
}

export async function loadPronunciations(): Promise<void> {
  if (!isMacOS() || pronunciationsLoaded) return;
  try {
    const homeDir = os.homedir();
    const plistPath = path.join(homeDir, "Library", "Speech", "Pronunciations.plist");
    pronunciationReplacements = await parsePronunciationsPlist(plistPath);
    pronunciationsLoaded = true;
  } catch {
    pronunciationReplacements = {};
    pronunciationsLoaded = true;
  }
}

export function getPronunciationReplacements(): PronunciationReplacements {
  return { ...pronunciationReplacements };
}

export function applyPronunciations(message: string): string {
  let result = message;
  const sortedKeys = Object.keys(pronunciationReplacements).sort(
    (a, b) => b.length - a.length
  );
  for (const key of sortedKeys) {
    const replacement = pronunciationReplacements[key];
    const regex = new RegExp(`\\b${escapeRegex(key)}\\b`, "gi");
    result = result.replace(regex, replacement);
  }
  return result;
}

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export const BEEP_SOUNDS = [
  "Tink", "Basso", "Blow", "Bottle", "Frog", "Funk",
  "Glass", "Hero", "Morse", "Ping", "Pop", "Purr",
  "Sosumi", "Submarine",
];

export const SAY_MESSAGES = [
  "Task completed",
  "Done",
  "Finished",
  "Ready",
  "All done",
  "Complete",
  "Task completed in {dirname}",
  "Done in {dirname}",
  "Finished in {dirname}",
  "All done in {dirname}",
  "{session dir} needs your attention",
];

const TERMINAL_BUNDLE_IDS: Record<string, string> = {
  "com.googlecode.iterm2": "iTerm2",
  "iTerm.app": "iTerm2",
};

const ITERM2_BUNDLE_IDS = ["com.googlecode.iterm2", "iTerm.app"];

export function isMacOS(): boolean {
  return process.platform === "darwin";
}

let hasSayCommand = false;

export async function checkSayAvailable(): Promise<boolean> {
  if (!isMacOS()) {
    hasSayCommand = false;
    return false;
  }
  try {
    await execAsync("which say");
    hasSayCommand = true;
    return true;
  } catch {
    hasSayCommand = false;
    return false;
  }
}

export function isSayAvailable(): boolean {
  return hasSayCommand;
}

export async function detectTerminalInfo(): Promise<TerminalInfo> {
  const info: TerminalInfo = {};
  if (!isMacOS()) return info;

  try {
    info.terminalPid = process.ppid;
    info.terminalApp = process.env.TERM_PROGRAM;

    info.terminalTTY = process.env.TTY;
    if (!info.terminalTTY) {
      try {
        const { stdout } = await execAsync(`ps -p ${process.ppid} -o tty=`);
        const tty = stdout.trim();
        if (tty && tty !== "??") {
          info.terminalTTY = tty.startsWith("/dev/") ? tty : "/dev/" + tty;
        }
      } catch {}
    }
    if (!info.terminalTTY && info.terminalPid) {
      try {
        const { stdout } = await execAsync(
          `lsof -p ${info.terminalPid} 2>/dev/null | grep -m1 "/dev/ttys" | awk '{print $9}'`
        );
        const tty = stdout.trim();
        if (tty?.startsWith("/dev/")) info.terminalTTY = tty;
      } catch {}
    }

    if (!info.terminalApp) {
      try {
        const { stdout } = await execAsync(`lsappinfo info -only bundleID ${info.terminalPid}`);
        const match = stdout.match(/"CFBundleIdentifier"="([^"]+)"/);
        if (match) info.terminalApp = match[1];
      } catch {
        info.terminalApp = "com.googlecode.iterm2";
      }
    }
  } catch {}

  return info;
}

export async function isTerminalInBackground(info: TerminalInfo): Promise<boolean> {
  if (!isMacOS()) return false;
  try {
    const { stdout } = await execAsync(
      "lsappinfo front | awk '{print $1}' | xargs -I {} lsappinfo info -only bundleID {}"
    );
    const match = stdout.match(/"CFBundleIdentifier"="([^"]+)"/);
    if (!match) return false;
    const frontBundleId = match[1];
    if (info.terminalApp && !frontBundleId.includes(info.terminalApp)) return true;
    const knownTerminals = Object.keys(TERMINAL_BUNDLE_IDS).filter((k) => k.includes("."));
    return !knownTerminals.some((id) => frontBundleId.includes(id));
  } catch {
    return false;
  }
}

let terminalNotifierAvailable = false;
let terminalNotifierChecked = false;
const TERMINAL_NOTIFIER_PATHS = [
  "/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier",
  "/usr/local/bin/terminal-notifier",
  "/opt/homebrew/bin/terminal-notifier",
];

export async function checkTerminalNotifierAvailable(): Promise<boolean> {
  if (!isMacOS() || terminalNotifierChecked) return terminalNotifierAvailable;
  try {
    await execAsync("which terminal-notifier");
    for (const p of TERMINAL_NOTIFIER_PATHS) {
      try {
        await execAsync(`test -f "${p}"`);
        terminalNotifierAvailable = true;
        break;
      } catch {}
    }
  } catch {
    terminalNotifierAvailable = false;
  }
  terminalNotifierChecked = true;
  return terminalNotifierAvailable;
}

export function isTerminalNotifierAvailable(): boolean {
  return terminalNotifierAvailable;
}

export function getCurrentDirName(): string {
  try {
    return process.cwd().split("/").pop() || "unknown";
  } catch {
    return "unknown";
  }
}

export function replaceMessageTemplates(message: string): string {
  const dirName = getCurrentDirName();
  return message
    .replace(/{session dir}/g, dirName)
    .replace(/{dirname}/g, dirName);
}

export function playBeep(soundName: string = "Tink"): void {
  if (isMacOS()) {
    child_process.spawn("afplay", [`/System/Library/Sounds/${soundName}.aiff`], {
      detached: true,
      stdio: "ignore",
    }).unref();
  } else if (process.platform === "linux") {
    try {
      child_process.spawn("paplay", ["/usr/share/sounds/freedesktop/stereo/bell.oga"], {
        detached: true,
        stdio: "ignore",
      }).unref();
    } catch {
      child_process.exec("echo -e '\\a'");
    }
  } else {
    child_process.exec("echo -e '\\a'");
  }
}

export function displayOSXNotification(
  message: string,
  soundName?: string,
  terminalInfo?: TerminalInfo
): void {
  if (!isMacOS()) {
    if (soundName) playBeep(soundName);
    return;
  }

  const finalMessage = replaceMessageTemplates(message);
  const terminalBundleId = "com.googlecode.iterm2";

  if (terminalNotifierAvailable) {
    if (terminalInfo?.terminalTTY) {
      const tty = terminalInfo.terminalTTY;
      const pythonScript = `#!/usr/bin/env python3
import sys
import os

tty = "${tty}"

try:
    import iterm2

    async def main(connection):
        app = await iterm2.async_get_app(connection)
        for window in app.terminal_windows:
            for tab in window.tabs:
                for session in tab.sessions:
                    try:
                        session_tty = await session.async_get_variable("tty")
                        if session_tty == tty or (session_tty and tty in str(session_tty)) or (tty and str(session_tty) in tty):
                            await app.async_activate()
                            await tab.async_activate(order_window_front=True)
                            return
                    except:
                        pass
        await app.async_activate()

    iterm2.run_until_complete(main)

except Exception:
    sys.exit(1)
`;
      const tmpFile = path.join(os.tmpdir(), `pi-notifier-${Date.now()}.py`);
      fs.writeFileSync(tmpFile, pythonScript, "utf-8");

      const args = [
        "-message", finalMessage,
        "-title", "Task Complete",
        "-activate", terminalBundleId,
        "-execute", `/opt/homebrew/Caskroom/miniconda/base/bin/python3 "${tmpFile}"`,
      ];
      if (soundName) args.push("-sound", soundName);

      child_process.spawn("terminal-notifier", args, {
        detached: true,
        stdio: "ignore",
      }).unref();
    } else {
      const args = [
        "-message", finalMessage,
        "-title", "Task Complete",
        "-activate", terminalBundleId,
      ];
      if (soundName) args.push("-sound", soundName);

      child_process.spawn("terminal-notifier", args, {
        detached: true,
        stdio: "ignore",
      }).unref();
    }
    return;
  }

  const escapedMessage = finalMessage
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"');
  const terminalAppName = "iTerm2";

  let script = `tell application "${terminalAppName}" to display notification "${escapedMessage}" with title "Task Complete"`;
  if (soundName) script += ` sound name "${soundName}"`;

  child_process.spawn("osascript", ["-e", script], {
    detached: true,
    stdio: "ignore",
  }).unref();
}

export function speakMessage(message: string): void {
  if (!isSayAvailable()) return;
  const finalMessage = replaceMessageTemplates(message);
  const messageWithPronunciations = applyPronunciations(finalMessage);
  const escapedMessage = messageWithPronunciations.replace(/"/g, '\\"');
  child_process.spawn("say", ["-v", "Daniel", escapedMessage], {
    detached: true,
    stdio: "ignore",
  }).unref();
}

export async function bringTerminalToFront(info: TerminalInfo): Promise<void> {
  if (!isMacOS()) return;

  try {
    let script: string;
    if (info.terminalTTY) {
      script = `tell application "iTerm2"
  repeat with w in windows
    set tabIdx to 0
    repeat with t in tabs of w
      set tabIdx to tabIdx + 1
      repeat with s in sessions of t
        if tty of s is "${info.terminalTTY}" then
          tell w to select tab tabIdx
          activate
          return
        end if
      end repeat
    end repeat
  end repeat
end tell`;
    } else {
      script = `tell application "iTerm2" to activate`;
    }

    const tmpFile = path.join(os.tmpdir(), `pi-terminal-${Date.now()}.scpt`);
    try {
      await fsPromises.writeFile(tmpFile, script, "utf8");
      await execAsync(`osascript "${tmpFile}"`);
    } finally {
      try { await fsPromises.unlink(tmpFile); } catch {}
    }
  } catch {}
}

export interface NotifyOptions {
  beep?: boolean;
  beepSound?: string;
  bringToFront?: boolean;
  say?: boolean;
  sayMessage?: string;
}

export async function notifyOnConfirm(
  config: BackgroundNotifyConfig,
  terminalInfo: TerminalInfo,
  options?: NotifyOptions
): Promise<void> {
  const eff = {
    beep: options?.beep ?? config.beep,
    beepSound: options?.beepSound ?? config.beepSound,
    bringToFront: options?.bringToFront ?? config.bringToFront,
    say: isSayAvailable() ? (options?.say ?? config.say) : false,
    sayMessage: options?.sayMessage ?? config.sayMessage,
  };

  const tasks: Promise<void>[] = [];

  if (eff.bringToFront) tasks.push(bringTerminalToFront(terminalInfo));
  if (eff.beep) playBeep(eff.beepSound);
  if (eff.say) speakMessage(eff.sayMessage);

  await Promise.all(tasks);
}
