/**
 * CWD Write Guard Extension
 *
 * Asks for permission before destructive operations target files
 * outside the current working directory:
 *   - edit/write tool calls with paths outside cwd
 *   - bash commands containing rm with paths outside cwd
 *   - bash commands that reference paths outside cwd (absolute, .., ~)
 *
 * Read and other non-destructive operations are always allowed.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve } from "node:path";
import { homedir } from "node:os";
import { realpathSync } from "node:fs";

export default function (pi: ExtensionAPI) {
  function safeRealpath(p: string): string {
    try {
      return realpathSync(p);
    } catch {
      // Path may not exist yet (e.g. new file); fall back to resolved path
      return resolve(p);
    }
  }

  function isOutsideCwd(path: string, cwd: string): boolean {
    const realCwd = safeRealpath(cwd);
    const realPath = safeRealpath(path);
    const cwdPrefix = realCwd.endsWith("/") ? realCwd : realCwd + "/";
    return !realPath.startsWith(cwdPrefix) && realPath !== realCwd;
  }

  function normalizeToolPath(inputPath: string, cwd: string): string {
    let p = inputPath;
    if (p.startsWith("@")) p = p.slice(1);
    if (p === "~") {
      p = homedir();
    } else if (p.startsWith("~/")) {
      p = resolve(homedir(), p.slice(2));
    } else if (!p.startsWith("/")) {
      p = resolve(cwd, p);
    }
    return resolve(p);
  }

  /**
   * Extract path-like tokens from a bash command that could reference
   * locations outside cwd: absolute paths, ..-relative paths, ~/paths.
   */
  function extractOutsidePaths(command: string, cwd: string): string[] {
    // Match tokens that look like paths:
    //   /absolute/path, ../relative, ~/home-relative
    const pathPattern = /(?:^|\s)((?:\/|\.\.\/|\.\.(?=\s|$)|~\/)\S*)/g;
    const outside: string[] = [];
    let match;

    while ((match = pathPattern.exec(command)) !== null) {
      let token = match[1].trim();
      // Expand ~ to home directory
      if (token.startsWith("~/")) {
        token = homedir() + token.slice(1);
      } else if (token === "~") {
        token = homedir();
      }
      const resolved = resolve(cwd, token);
      if (isOutsideCwd(resolved, cwd)) {
        outside.push(resolved);
      }
    }

    return outside;
  }

  async function askPermission(
    ctx: any,
    action: string,
    paths: string[]
  ): Promise<{ block: boolean; reason: string } | undefined> {
    const pathList = paths.map((p) => `  ${p}`).join("\n");

    if (!ctx.hasUI) {
      return { block: true, reason: `Blocked ${action} outside cwd (no UI for confirmation):\n${pathList}` };
    }

    const choice = await ctx.ui.select(
      `⚠️ ${action} outside working directory:\n\n${pathList}\n\nAllow?`,
      ["Yes", "No"]
    );

    if (choice !== "Yes") {
      return { block: true, reason: "Blocked by user" };
    }

    return undefined;
  }

  pi.on("tool_call", async (event, ctx) => {
    const cwd = ctx.cwd;

    // --- edit / write ---
    if (event.toolName === "write" || event.toolName === "edit") {
      const rawPath = event.input.path as string;
      const targetPath = normalizeToolPath(rawPath, cwd);
      if (isOutsideCwd(targetPath, cwd)) {
        return askPermission(ctx, event.toolName, [targetPath]);
      }
      return undefined;
    }

    // --- bash ---
    if (event.toolName === "bash") {
      const command = event.input.command as string;
      const outsidePaths = extractOutsidePaths(command, cwd);

      if (outsidePaths.length === 0) return undefined;

      // Destructive commands targeting outside paths → always ask
      const destructive = /\b(rm|rmdir|mv|cp|chmod|chown|truncate|shred|dd)\b/;
      if (destructive.test(command)) {
        return askPermission(ctx, `bash (${command.split(/\s+/)[0]})`, outsidePaths);
      }

      // Non-destructive bash with outside paths → allow
      return undefined;
    }

    return undefined;
  });
}
