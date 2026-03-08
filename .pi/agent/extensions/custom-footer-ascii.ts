import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
	let enabled = true;

	function installFooter(ctx: any, { notify }: { notify: boolean }) {
		if (!ctx.hasUI) return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					let input = 0;
					let output = 0;
					let cost = 0;

					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type !== "message") continue;
						if (e.message.role !== "assistant") continue;
						const m = e.message as AssistantMessage;
						input += m.usage.input;
						output += m.usage.output;
						cost += m.usage.cost.total;
					}

					const fmtTokens = (n: number) => {
						if (n < 1000) return `${n}`;
						return `${(n / 1000).toFixed(1)}k`;
					};

					// Line 1: current working directory + optional git branch
					let cwd = ctx.cwd as string;
					const home = process.env.HOME || process.env.USERPROFILE;
					if (home && cwd.startsWith(home)) {
						cwd = `~${cwd.slice(home.length)}`;
					}
					const branch = footerData.getGitBranch();
					const branchSuffix = branch ? ` (${branch})` : "";
					const cwdLine = truncateToWidth(theme.fg("dim", `${cwd}${branchSuffix}`), width);

					// Line 2: ASCII token stats + model id + thinking level (if supported)
					const leftRaw = `in:${fmtTokens(input)} out:${fmtTokens(output)} $${cost.toFixed(3)}`;
					const left = theme.fg("dim", leftRaw);

					let rightRaw = ctx.model?.id || "no-model";
					if (ctx.model?.reasoning) {
						const thinkingLevel = pi.getThinkingLevel();
						rightRaw = thinkingLevel === "off" ? `${rightRaw} • thinking off` : `${rightRaw} • ${thinkingLevel}`;
					}
					const right = theme.fg("dim", rightRaw);

					const padWidth = Math.max(1, width - visibleWidth(left) - visibleWidth(right));
					const pad = " ".repeat(padWidth);
					const statsLine = truncateToWidth(left + pad + right, width);

					return [cwdLine, statsLine];
				},
			};
		});

		enabled = true;
		if (notify) {
			ctx.ui.notify("ASCII footer enabled", "info");
		}
	}

	function clearFooter(ctx: any, { notify }: { notify: boolean }) {
		if (!ctx.hasUI) return;
		ctx.ui.setFooter(undefined);
		enabled = false;
		if (notify) {
			ctx.ui.notify("Default footer restored", "info");
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		if (enabled) {
			installFooter(ctx, { notify: false });
		}
	});

	pi.on("session_switch", async (_event, ctx) => {
		if (enabled) {
			installFooter(ctx, { notify: false });
		} else {
			clearFooter(ctx, { notify: false });
		}
	});

	pi.registerCommand("footer-ascii", {
		description: "Toggle ASCII stats footer (no arrows)",
		handler: async (_args, ctx) => {
			if (enabled) {
				clearFooter(ctx, { notify: true });
			} else {
				installFooter(ctx, { notify: true });
			}
		},
	});
}
