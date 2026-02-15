import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.registerCommand("theme", {
		description: "Switch theme",
		getArgumentCompletions: (prefix, ctx) => {
			const themes = ctx.ui.getAllThemes();
			const items = themes.map((t) => ({ value: t.name, label: t.name }));
			const filtered = items.filter((i) => i.value.startsWith(prefix));
			return filtered.length > 0 ? filtered : null;
		},
		handler: async (args, ctx) => {
			const themes = ctx.ui.getAllThemes();
			const currentName = ctx.ui.theme.name ?? "unknown";

			if (args.trim()) {
				const result = ctx.ui.setTheme(args.trim());
				if (result.success) {
					ctx.ui.notify(`Theme: ${args.trim()}`, "success");
				} else {
					ctx.ui.notify(result.error ?? "Failed to set theme", "error");
				}
				return;
			}

			const items = themes.map((t) =>
				t.name === currentName ? `${t.name} (current)` : t.name
			);

			const selected = await ctx.ui.select("Select theme", items);
			if (!selected) return;

			const themeName = selected.replace(" (current)", "");
			const result = ctx.ui.setTheme(themeName);
			if (result.success) {
				ctx.ui.notify(`Theme: ${themeName}`, "success");
			} else {
				ctx.ui.notify(result.error ?? "Failed to set theme", "error");
			}
		},
	});
}
