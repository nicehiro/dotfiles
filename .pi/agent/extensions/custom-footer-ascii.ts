import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
	let enabled = true;

	function installFooter(ctx: any, { notify }: { notify: boolean }) {
		if (!ctx.hasUI) return;

		ctx.ui.setFooter((_tui, theme) => ({
			invalidate() {},
			render(width: number): string[] {
				let cost = 0;

				for (const e of ctx.sessionManager.getEntries()) {
					if (e.type !== "message") continue;
					if (e.message.role !== "assistant") continue;
					const usage = (e.message as { usage?: { cost?: { total?: number } } }).usage;
					cost += usage?.cost?.total ?? 0;
				}

				const fmtTokens = (n: number) => {
					if (n < 1000) return `${n}`;
					if (n < 10000) return `${(n / 1000).toFixed(1)}k`;
					if (n < 1000000) return `${Math.round(n / 1000)}k`;
					if (n < 10000000) return `${(n / 1000000).toFixed(1)}M`;
					return `${Math.round(n / 1000000)}M`;
				};

				const contextUsage = ctx.getContextUsage?.();
				const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
				const usedTokens = contextUsage?.tokens ?? null;
				const contextPart = `${usedTokens === null ? "?" : fmtTokens(usedTokens)}/${fmtTokens(contextWindow)}`;
				const thinkingLevel = pi.getThinkingLevel();
				const statusRaw = [contextPart, `$${cost.toFixed(3)}`, thinkingLevel === "off" ? "thinking off" : thinkingLevel].join(
					" • ",
				);
				const status = theme.fg("dim", statusRaw);
				const pad = " ".repeat(Math.max(0, width - visibleWidth(status)));

				return [truncateToWidth(pad + status, width)];
			},
		}));

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
		description: "Toggle minimal stats footer",
		handler: async (_args, ctx) => {
			if (enabled) {
				clearFooter(ctx, { notify: true });
			} else {
				installFooter(ctx, { notify: true });
			}
		},
	});
}
