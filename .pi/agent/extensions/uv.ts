/**
 * UV Extension - Redirects Python tooling to uv equivalents
 *
 * This extension intercepts bash tool calls to prepend intercepted-commands to
 * PATH. Those shims intercept common Python tooling commands and redirect
 * agents to use uv instead.
 *
 * Intercepted commands:
 * - pip/pip3: Blocked with suggestions to use `uv add` or `uv run --with`
 * - poetry: Blocked with uv equivalents (uv init, uv add, uv sync, uv run)
 * - python/python3: Redirected to `uv run python`, with special handling to
 *   block `python -m pip` and `python -m venv`
 *
 * The shim scripts are located in the intercepted-commands directory and
 * provide helpful error messages with the equivalent uv commands.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const interceptedCommandsPath = join(__dirname, "..", "intercepted-commands");
const pathPrefix = `export PATH="${interceptedCommandsPath}:$PATH"`;

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", (event) => {
    if (!isToolCallEventType("bash", event)) return;
    event.input.command = `${pathPrefix}\n${event.input.command}`;
  });

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.notify("UV interceptor loaded", "info");
  });
}
