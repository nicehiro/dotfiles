import { spawn } from "node:child_process";
import { watch, type FSWatcher } from "node:fs";
import { readFile, stat } from "node:fs/promises";
import { basename, dirname } from "node:path";
import { renderAsync, Resvg } from "@resvg/resvg-js";
import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Container, Image, Text } from "@earendil-works/pi-tui";
import {
	formatUpdatedTime,
	resolveSvgPath,
	selectSvgFit,
	validateSvgBuffer,
	validateSvgSize,
} from "./lib.ts";

const WIDGET_ID = "svg-preview";
const DEBOUNCE_MS = 150;

type PreviewState = {
	image?: string;
	status: "loading" | "ready" | "error";
	message?: string;
	updatedAt?: number;
};

const readSvg = async (path: string): Promise<Buffer> => {
	const info = await stat(path);
	if (!info.isFile()) throw new Error("Path is not a regular file");
	validateSvgSize(info.size);
	const source = await readFile(path);
	validateSvgBuffer(source);
	return source;
};

const renderSvg = async (source: Buffer): Promise<string> => {
	const probe = new Resvg(source, { font: { loadSystemFonts: false }, logLevel: "off" });
	const rendered = await renderAsync(source, { fitTo: selectSvgFit(probe.width, probe.height) });
	return rendered.asPng().toString("base64");
};

const errorMessage = (error: unknown): string => {
	if (error && typeof error === "object" && "code" in error && error.code === "ENOENT") {
		return "File missing - waiting for it to reappear";
	}
	return error instanceof Error ? error.message : String(error);
};

const copyToClipboard = (source: Buffer): Promise<void> => new Promise((resolve, reject) => {
	const child = spawn("pbcopy", [], { stdio: ["pipe", "ignore", "pipe"] });
	let stderr = "";
	child.stderr.setEncoding("utf8");
	child.stderr.on("data", (chunk: string) => { stderr += chunk; });
	child.on("error", reject);
	child.on("close", (code) => {
		if (code === 0) resolve();
		else reject(new Error(stderr.trim() || `pbcopy exited with code ${code}`));
	});
	child.stdin.on("error", reject);
	child.stdin.end(source);
});

class PreviewController {
	private context?: ExtensionContext;
	private path?: string;
	private watcher?: FSWatcher;
	private debounce?: NodeJS.Timeout;
	private generation = 0;
	private state: PreviewState = { status: "loading" };

	async open(path: string, ctx: ExtensionCommandContext): Promise<void> {
		const source = await readSvg(path);
		const image = await renderSvg(source);

		this.close();
		this.context = ctx;
		this.path = path;
		this.state = {
			image,
			status: "ready",
			updatedAt: Date.now(),
		};
		this.installWidget();
		this.startWatcher();

		try {
			const latest = await readSvg(path);
			if (!latest.equals(source)) this.scheduleRefresh(0);
		} catch {
			this.scheduleRefresh(0);
		}
	}

	async copy(): Promise<string> {
		const path = this.path;
		if (!path) throw new Error("No SVG preview is open");
		await copyToClipboard(await readSvg(path));
		return path;
	}

	close(ctx?: ExtensionContext): void {
		this.generation++;
		if (this.debounce) clearTimeout(this.debounce);
		this.debounce = undefined;
		this.watcher?.close();
		this.watcher = undefined;
		(ctx ?? this.context)?.ui.setWidget(WIDGET_ID, undefined);
		this.context = undefined;
		this.path = undefined;
		this.state = { status: "loading" };
	}

	private startWatcher(): void {
		if (!this.path) return;
		const target = basename(this.path).normalize("NFC");
		this.watcher = watch(dirname(this.path), { persistent: false }, (_event, filename) => {
			if (filename !== null && filename.toString().normalize("NFC") !== target) return;
			this.scheduleRefresh();
		});
		this.watcher.on("error", (error) => this.setError(`Watcher failed: ${error.message}`));
	}

	private scheduleRefresh(delay = DEBOUNCE_MS): void {
		if (this.debounce) clearTimeout(this.debounce);
		this.debounce = setTimeout(() => {
			this.debounce = undefined;
			void this.refresh();
		}, delay);
	}

	private async refresh(): Promise<void> {
		if (!this.path) return;
		const path = this.path;
		const generation = ++this.generation;
		this.state = { ...this.state, status: "loading", message: undefined };
		this.installWidget();

		try {
			const source = await readSvg(path);
			const image = await renderSvg(source);
			if (generation !== this.generation || path !== this.path) return;
			this.state = {
				image,
				status: "ready",
				updatedAt: Date.now(),
			};
			this.installWidget();
		} catch (error) {
			if (generation !== this.generation || path !== this.path) return;
			this.setError(errorMessage(error));
		}
	}

	private setError(message: string): void {
		this.state = { ...this.state, status: "error", message };
		this.installWidget();
	}

	private installWidget(): void {
		if (!this.context || !this.path) return;
		const path = this.path;
		const state = { ...this.state };
		this.context.ui.setWidget(WIDGET_ID, (_tui, theme) => {
			const container = new Container();
			let header = theme.fg("accent", `svgp: ${basename(path)}`);
			if (state.status === "ready" && state.updatedAt) {
				header += theme.fg("dim", `  updated ${formatUpdatedTime(state.updatedAt)}`);
			} else if (state.status === "loading") {
				header += theme.fg("dim", "  updating...");
			} else {
				header += `\n${theme.fg("warning", state.message ?? "Unable to render SVG")}`;
			}
			container.addChild(new Text(header, 0, 0));
			if (state.image) {
				container.addChild(new Image(state.image, "image/png", {
					fallbackColor: (text) => theme.fg("dim", text),
				}, {
					filename: path,
					maxWidthCells: 80,
					maxHeightCells: 24,
				}));
			}
			container.addChild(new Text(theme.fg("dim", "/svgp-copy  /svgp-close"), 0, 0));
			return container;
		}, { placement: "belowEditor" });
	}
}

export default function (pi: ExtensionAPI) {
	const controller = new PreviewController();

	pi.registerCommand("svgp", {
		description: "Show a live SVG preview below the editor",
		handler: async (args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("SVG preview is only available in interactive TUI mode", "error");
				return;
			}

			try {
				const path = resolveSvgPath(args, ctx.cwd);
				await controller.open(path, ctx);
				ctx.ui.notify(`Previewing ${path}`, "info");
			} catch (error) {
				ctx.ui.notify(`SVG preview failed: ${errorMessage(error)}`, "error");
			}
		},
	});

	pi.registerCommand("svgp-copy", {
		description: "Copy the current SVG source for pasting into Figma",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("SVG preview is only available in interactive TUI mode", "error");
				return;
			}

			try {
				const copiedPath = await controller.copy();
				ctx.ui.notify(`Copied ${basename(copiedPath)} for Figma`, "info");
			} catch (error) {
				ctx.ui.notify(`SVG copy failed: ${errorMessage(error)}`, "error");
			}
		},
	});

	pi.registerCommand("svgp-close", {
		description: "Close the live SVG preview",
		handler: async (_args, ctx) => {
			controller.close(ctx);
			ctx.ui.notify("SVG preview closed", "info");
		},
	});

	pi.on("session_shutdown", (_event, ctx) => controller.close(ctx));
}
