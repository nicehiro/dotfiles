import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let requestFooterRender: (() => void) | undefined;
	let currentModel: { provider?: string; id?: string; contextWindow?: number } | undefined;

	function installFooter(ctx: any, { notify }: { notify: boolean }) {
		if (!ctx.hasUI) return;
		currentModel = ctx.model;

		ctx.ui.setFooter((tui, theme, footerData) => {
			const renderFooter = () => tui.requestRender();
			requestFooterRender = renderFooter;
			const unsub = footerData.onBranchChange(renderFooter);

			return {
				dispose() {
					unsub();
					if (requestFooterRender === renderFooter) {
						requestFooterRender = undefined;
					}
				},
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

					let cwd = ctx.cwd as string;
					const home = process.env.HOME || process.env.USERPROFILE;
					if (home && cwd.startsWith(home)) {
						cwd = `~${cwd.slice(home.length)}`;
					}
					const branch = footerData.getGitBranch();
					const leftRaw = branch ? `${cwd} (${branch})` : cwd;

					const contextUsage = ctx.getContextUsage?.();
					const model = currentModel ?? ctx.model;
					const modelPart = model?.id ?? "no model";
					const contextWindow = contextUsage?.contextWindow ?? model?.contextWindow ?? 0;
					const usedTokens = contextUsage?.tokens ?? null;
					const contextPart = `${usedTokens === null ? "?" : fmtTokens(usedTokens)}/${fmtTokens(contextWindow)}`;
					const thinkingLevel = pi.getThinkingLevel();
					const statusRaw = [modelPart, contextPart, `$${cost.toFixed(3)}`, thinkingLevel === "off" ? "thinking off" : thinkingLevel].join(
						" • ",
					);
					const status = theme.fg("dim", statusRaw);
					const leftWidth = Math.max(0, width - visibleWidth(status) - 1);
					const left = theme.fg("dim", truncateToWidth(leftRaw, leftWidth, ""));
					const pad = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(status)));

					return [truncateToWidth(left + pad + status, width)];
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
		requestFooterRender = undefined;
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

	pi.on("model_select", async (event) => {
		currentModel = event.model;
		requestFooterRender?.();
	});

	pi.on("thinking_level_select", async () => {
		requestFooterRender?.();
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
