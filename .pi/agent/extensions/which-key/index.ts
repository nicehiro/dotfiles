/**
 * Which-Key Extension
 *
 * Shows available keybindings in a searchable panel.
 * Trigger with Ctrl+/ or /which-key.
 */

import type { ExtensionAPI, KeybindingsManager } from "@mariozechner/pi-coding-agent";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  CURSOR_MARKER,
} from "@mariozechner/pi-tui";

const DESC: Record<string, string> = {
  cursorUp: "Move cursor up",
  cursorDown: "Move cursor down",
  cursorLeft: "Move cursor left",
  cursorRight: "Move cursor right",
  cursorWordLeft: "Move cursor word left",
  cursorWordRight: "Move cursor word right",
  cursorLineStart: "Move to line start",
  cursorLineEnd: "Move to line end",
  jumpForward: "Jump forward to character",
  jumpBackward: "Jump backward to character",
  pageUp: "Scroll up by page",
  pageDown: "Scroll down by page",
  deleteCharBackward: "Delete char backward",
  deleteCharForward: "Delete char forward",
  deleteWordBackward: "Delete word backward",
  deleteWordForward: "Delete word forward",
  deleteToLineStart: "Delete to line start",
  deleteToLineEnd: "Delete to line end",
  newLine: "Insert new line",
  submit: "Submit input",
  tab: "Tab / autocomplete",
  yank: "Paste recently deleted text",
  yankPop: "Cycle through deleted text",
  undo: "Undo last edit",
  copy: "Copy selection",
  pasteImage: "Paste image from clipboard",
  interrupt: "Cancel / abort",
  clear: "Clear editor",
  exit: "Exit (when editor empty)",
  suspend: "Suspend to background",
  externalEditor: "Open in external editor",
  newSession: "Start a new session",
  tree: "Open session tree",
  fork: "Fork current session",
  resume: "Resume session",
  selectModel: "Open model selector",
  cycleModelForward: "Cycle to next model",
  cycleModelBackward: "Cycle to prev model",
  cycleThinkingLevel: "Cycle thinking level",
  expandTools: "Collapse/expand tool output",
  toggleThinking: "Collapse/expand thinking",
  followUp: "Queue follow-up message",
  dequeue: "Restore queued messages",
  selectUp: "Move selection up",
  selectDown: "Move selection down",
  selectPageUp: "Page up in list",
  selectPageDown: "Page down in list",
  selectConfirm: "Confirm selection",
  selectCancel: "Cancel selection",
  toggleSessionPath: "Toggle path display",
  toggleSessionSort: "Toggle sort mode",
  toggleSessionNamedFilter: "Toggle named-only filter",
  renameSession: "Rename session",
  deleteSession: "Delete session",
  deleteSessionNoninvasive: "Delete session (safe)",
};

const CATEGORIES: { name: string; actions: string[] }[] = [
  { name: "Application", actions: ["interrupt", "clear", "exit", "suspend", "externalEditor"] },
  { name: "Text Input", actions: ["submit", "newLine", "tab"] },
  {
    name: "Cursor",
    actions: [
      "cursorUp", "cursorDown", "cursorLeft", "cursorRight",
      "cursorWordLeft", "cursorWordRight", "cursorLineStart", "cursorLineEnd",
      "jumpForward", "jumpBackward", "pageUp", "pageDown",
    ],
  },
  {
    name: "Deletion",
    actions: [
      "deleteCharBackward", "deleteCharForward",
      "deleteWordBackward", "deleteWordForward",
      "deleteToLineStart", "deleteToLineEnd",
    ],
  },
  { name: "Kill Ring & Clipboard", actions: ["yank", "yankPop", "undo", "copy", "pasteImage"] },
  { name: "Session", actions: ["newSession", "tree", "fork", "resume"] },
  { name: "Models & Thinking", actions: ["selectModel", "cycleModelForward", "cycleModelBackward", "cycleThinkingLevel"] },
  { name: "Display", actions: ["expandTools", "toggleThinking"] },
  { name: "Message Queue", actions: ["followUp", "dequeue"] },
];

function fmtKey(key: string): string {
  return key
    .replace(/ctrl\+/g, "C-")
    .replace(/alt\+/g, "M-")
    .replace(/shift\+/g, "S-")
    .replace("escape", "Esc")
    .replace("enter", "⏎")
    .replace("return", "⏎")
    .replace("space", "Space")
    .replace("backspace", "⌫")
    .replace("delete", "Del")
    .replace("pageUp", "PgUp")
    .replace("pageDown", "PgDn");
}

interface KeyEntry { keys: string[]; description: string }
interface KeyGroup { name: string; entries: KeyEntry[] }

function buildGroups(config: Record<string, any>): KeyGroup[] {
  const groups: KeyGroup[] = [];
  for (const cat of CATEGORIES) {
    const entries: KeyEntry[] = [];
    for (const action of cat.actions) {
      const raw = config[action];
      if (!raw) continue;
      const keys = (Array.isArray(raw) ? raw : [raw]).filter((k: string) => k.length > 0).map(fmtKey);
      if (keys.length === 0) continue;
      entries.push({ keys, description: DESC[action] || action });
    }
    if (entries.length > 0) groups.push({ name: cat.name, entries });
  }
  return groups;
}

function filterGroups(groups: KeyGroup[], q: string): KeyGroup[] {
  if (!q) return groups;
  const lq = q.toLowerCase();
  return groups
    .map((g) => ({
      name: g.name,
      entries: g.entries.filter(
        (e) =>
          e.description.toLowerCase().includes(lq) ||
          e.keys.some((k) => k.toLowerCase().includes(lq)),
      ),
    }))
    .filter((g) => g.entries.length > 0);
}

export default function whichKeyExtension(pi: ExtensionAPI) {
  const BOX_W = 72;
  const INNER = BOX_W - 4; // border + 1 char padding each side

  async function showWhichKey(ctx: any) {
    if (!ctx.hasUI) return;

    await ctx.ui.custom<void>(
      (tui: any, theme: any, keybindings: KeybindingsManager, done: (v: void) => void) => {
        const config = keybindings.getEffectiveConfig();
        const groups = buildGroups(config);

        const cmds = pi.getCommands().filter((c: any) => c.source === "extension");
        if (cmds.length > 0) {
          groups.push({
            name: "Extension Commands",
            entries: cmds.map((c: any) => ({
              keys: ["/" + c.name],
              description: c.description || c.name,
            })),
          });
        }

        let query = "";
        let scrollOffset = 0;

        const border = (l: string, f: string, r: string) =>
          theme.fg("border", l + f.repeat(BOX_W - 2) + r);

        const row = (content: string) => {
          const w = visibleWidth(content);
          const pad = Math.max(0, INNER - w);
          return (
            theme.fg("border", "│") +
            " " +
            truncateToWidth(content, INNER) +
            " ".repeat(pad) +
            " " +
            theme.fg("border", "│")
          );
        };

        return {
          focused: true,
          width: BOX_W,

          handleInput(data: string) {
            if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
              done(undefined);
              return;
            }
            if (matchesKey(data, Key.up) || matchesKey(data, Key.ctrl("p"))) {
              scrollOffset = Math.max(0, scrollOffset - 1);
              tui.requestRender();
              return;
            }
            if (matchesKey(data, Key.down) || matchesKey(data, Key.ctrl("n"))) {
              scrollOffset++;
              tui.requestRender();
              return;
            }
            if (matchesKey(data, "pageUp")) {
              scrollOffset = Math.max(0, scrollOffset - 10);
              tui.requestRender();
              return;
            }
            if (matchesKey(data, "pageDown")) {
              scrollOffset += 10;
              tui.requestRender();
              return;
            }
            if (matchesKey(data, Key.backspace)) {
              if (query.length > 0) {
                query = query.slice(0, -1);
                scrollOffset = 0;
                tui.requestRender();
              }
              return;
            }
            if (matchesKey(data, Key.ctrl("u"))) {
              query = "";
              scrollOffset = 0;
              tui.requestRender();
              return;
            }
            if (data.length === 1 && data.charCodeAt(0) >= 32) {
              query += data;
              scrollOffset = 0;
              tui.requestRender();
            }
          },

          render(_width: number): string[] {
            const termH = tui.height || process.stdout.rows || 24;
            const filtered = filterGroups(groups, query);

            // Build content lines
            const content: string[] = [];
            if (filtered.length === 0) {
              content.push(theme.fg("warning", "  No matches"));
            } else {
              for (let i = 0; i < filtered.length; i++) {
                const g = filtered[i];
                if (i > 0) content.push("");
                content.push(theme.fg("accent", " " + g.name));
                for (const e of g.entries) {
                  const keysStr = e.keys
                    .map((k: string) => theme.bold(theme.fg("text", k)))
                    .join(theme.fg("dim", " "));
                  const rawKeysLen = e.keys.join(" ").length;
                  const gap = Math.max(1, 20 - rawKeysLen);
                  content.push(
                    "  " + keysStr + " ".repeat(gap) + theme.fg("muted", e.description),
                  );
                }
              }
            }

            // chrome: 4 top + 3 bottom = 7 lines from our own borders
            const maxContent = Math.max(3, termH - 7);
            const maxScroll = Math.max(0, content.length - maxContent);
            if (scrollOffset > maxScroll) scrollOffset = maxScroll;
            const visible = content.slice(scrollOffset, scrollOffset + maxContent);

            const lines: string[] = [];
            lines.push(border("╭", "─", "╮"));
            lines.push(row(theme.fg("accent", theme.bold("⌨  Which Key"))));
            const searchDisplay = query
              ? theme.fg("text", query) + CURSOR_MARKER + theme.fg("dim", "▏")
              : theme.fg("dim", "type to filter...") + CURSOR_MARKER;
            lines.push(row(theme.fg("muted", "❯ ") + searchDisplay));
            lines.push(border("├", "─", "┤"));

            for (const c of visible) lines.push(row(c));

            lines.push(border("├", "─", "┤"));
            const scrollPct =
              content.length > maxContent
                ? " " +
                  theme.fg(
                    "dim",
                    `${Math.min(100, Math.round(((scrollOffset + maxContent) / content.length) * 100))}%`,
                  )
                : "";
            const hint =
              theme.fg("dim", "Esc close  ↑↓ scroll  type to filter") + scrollPct;
            lines.push(row(hint));
            lines.push(border("╰", "─", "╯"));

            return lines;
          },

          invalidate() {},
        };
      },
      { overlay: true },
    );
  }

  pi.registerShortcut(Key.ctrl("/"), {
    description: "Show keybindings (which-key)",
    handler: async (ctx) => {
      await showWhichKey(ctx);
    },
  });

  pi.registerCommand("which-key", {
    description: "Show all keybindings",
    handler: async (_args, ctx) => {
      await showWhichKey(ctx);
    },
  });
}
