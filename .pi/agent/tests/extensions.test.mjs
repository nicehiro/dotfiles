import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, realpathSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createRequire } from "node:module";
import test from "node:test";

const piRequire = createRequire(realpathSync(execFileSync("which", ["pi"], { encoding: "utf8" }).trim()));
const { createJiti } = piRequire("jiti");
const resolver = createJiti(piRequire.resolve("jiti"));
const alias = Object.fromEntries([
	"@earendil-works/pi-coding-agent", "@earendil-works/pi-ai", "@earendil-works/pi-tui", "typebox",
].map((name) => [name, resolver.esmResolve(name === "@earendil-works/pi-ai" ? `${name}/compat` : name)]));
const jiti = createJiti(import.meta.url, { alias });
const load = (file) => jiti.import(new URL(`../extensions/${file}.ts`, import.meta.url).pathname);
const { default: goalExtension, assistantUsageTokens } = await load("goal");
const { default: answerExtension, parseExtractionResult, selectExtractionModel } = await load("answer");
const { formatNotification } = await load("notify");
const { PromptEditor } = await load("prompt-editor");
const { buildRangeAgg, addSessionToRange, choosePaletteFromLast30Days, renderModelTable, BreakdownComponent } = await load("session-breakdown");
const { visibleWidth, stripTerminalSequences, KeybindingsManager, TUI_KEYBINDINGS } = await jiti.import(alias["@earendil-works/pi-tui"]);
const { initTheme, DefaultResourceLoader, SettingsManager } = await jiti.import(alias["@earendil-works/pi-coding-agent"]);
initTheme("dark");

function goalHarness(entries = [], hasUI = false) {
	const handlers = new Map(), tools = new Map(), commands = new Map(), sent = [];
	const ctx = {
		hasUI, isIdle: () => true, hasPendingMessages: () => false,
		sessionManager: { getBranch: () => entries, getSessionId: () => "test-session" },
		ui: { setStatus() {}, notify() {}, theme: { fg: (_, text) => text }, confirm: async () => true, editor: async () => "Edited goal" },
	};
	goalExtension({
		on: (name, handler) => handlers.set(name, handler),
		registerTool: (tool) => tools.set(tool.name, tool),
		registerCommand: (name, command) => commands.set(name, command),
		appendEntry: (customType, data) => entries.push({ type: "custom", customType, data: structuredClone(data) }),
		sendMessage: (message, options) => sent.push({ ...message, options }),
	});
	const emit = (name, event = {}) => handlers.get(name)(event, ctx);
	const call = async (name, params = {}) => (await tools.get(name).execute("test", params, undefined, undefined, ctx)).details;
	return { ctx, entries, sent, emit, call, command: (args) => commands.get("goal").handler(args, ctx) };
}

function assistant(stopReason = "stop", errorMessage, usage = { input: 10, output: 5 }) {
	return { role: "assistant", stopReason, errorMessage, usage };
}

test("goal budget counts input + output without subtracting cache twice", () => {
	assert.equal(assistantUsageTokens([
		assistant("stop", undefined, { input: 100, output: 20, cacheRead: 900, cacheWrite: 50, totalTokens: 1070 }),
		{ role: "user", usage: { input: 999 } }, assistant("stop", undefined, { input: -1, output: 2 }),
	]), 122);
});

test("goals stop on provider errors and resume explicitly", async () => {
	for (const [error, status] of [["Rate limit exceeded", "usageLimited"], ["Quota exhausted", "usageLimited"], ["Connection failed", "blocked"]]) {
		const h = goalHarness();
		await h.call("create_goal", { objective: "Finish task" });
		await h.emit("agent_start");
		await h.emit("agent_end", { messages: [assistant("error", error)] });
		assert.equal((await h.call("get_goal")).goal.status, status);
		assert.equal(h.sent.filter((m) => m.options.triggerTurn).length, 0);
		await h.command("resume");
		assert.equal((await h.call("get_goal")).goal.status, "active");
		assert.equal(h.sent.filter((m) => m.options.triggerTurn).length, 1);
	}
});

test("aborted goals pause headlessly and honor the interactive pause decision", async () => {
	for (const [hasUI, pause, expected] of [[false, true, "paused"], [true, true, "paused"], [true, false, "active"]]) {
		const h = goalHarness([], hasUI);
		h.ctx.ui.confirm = async () => pause;
		await h.call("create_goal", { objective: "Finish task" });
		await h.emit("agent_start");
		await h.emit("agent_end", { messages: [assistant("aborted")] });
		assert.equal((await h.call("get_goal")).goal.status, expected);
		assert.equal(h.sent.some((m) => m.options.triggerTurn), expected === "active");
	}
});

test("exhausted budgets prevent continuation after resume or objective editing", async () => {
	const h = goalHarness([], true);
	await h.call("create_goal", { objective: "Finish task", token_budget: 15 });
	await h.emit("agent_start");
	await h.emit("agent_end", { messages: [assistant()] });
	assert.equal((await h.call("get_goal")).goal.status, "budgetLimited");
	await h.command("resume");
	await h.command("edit");
	assert.equal((await h.call("get_goal")).goal.status, "budgetLimited");
	assert.equal(h.sent.some((m) => m.options.triggerTurn), false);
});

test("completed goals can be replaced, unfinished goals cannot", async () => {
	const h = goalHarness();
	await h.call("create_goal", { objective: "First" });
	await assert.rejects(h.call("create_goal", { objective: "Second" }), /unfinished/);
	await h.call("update_goal", { status: "blocked" });
	assert.equal((await h.call("get_goal")).goal.status, "blocked");
	await assert.rejects(h.call("update_goal", { status: "paused" }), /complete or blocked/);
	await h.call("update_goal", { status: "complete" });
	await h.call("create_goal", { objective: "Second" });
	assert.equal((await h.call("get_goal")).goal.objective, "Second");
});

test("goal edit and status survive reload and tree navigation from v1 state", async () => {
	const entries = [{ type: "custom", customType: "goal", data: { version: 1, action: "set", goal: {
		id: "legacy", objective: "Original", status: "paused", tokensUsed: 42, timeUsedSeconds: 3, createdAt: 1, updatedAt: 1,
	} } }];
	const h = goalHarness(entries, true);
	await h.emit("session_start");
	await h.command("edit");
	assert.equal(entries.at(-1).data.version, 2);
	assert.equal((await h.call("get_goal")).goal.objective, "Edited goal");
	assert.equal((await h.call("get_goal")).goal.status, "paused");
	const restored = goalHarness(entries);
	await restored.emit("session_start");
	assert.equal((await restored.call("get_goal")).goal.tokensUsed, 42);
	entries.pop();
	await restored.emit("session_tree");
	assert.equal((await restored.call("get_goal")).goal.objective, "Original");
});

test("active goals deduplicate continuations and discard stale context", async () => {
	const h = goalHarness();
	await h.call("create_goal", { objective: "Task <data>" });
	await h.emit("agent_start");
	await h.emit("agent_end", { messages: [assistant()] });
	await h.emit("agent_end", { messages: [] });
	const continuations = h.sent.filter((m) => m.options.triggerTurn);
	assert.equal(continuations.length, 1);
	assert.match(continuations[0].content, /Task &lt;data&gt;/);
	const messages = [{ customType: "goal-ui" }, { customType: "goal-continuation", details: { goalId: "old" } }, continuations[0], continuations[0]];
	assert.equal((await h.emit("context", { messages })).messages.length, 1);
	await h.command("pause");
	assert.equal((await h.emit("context", { messages })).messages.length, 0);
});

test("question extraction repairs JSON and rejects invalid shapes", () => {
	for (const text of ['{"questions":[{"question":"Why?"}]}', '```json\n{"questions":[{"question":"Why?"}]}\n```', 'Result: {"questions":[{"question":"Why?"}]} Done.']) {
		assert.deepEqual(parseExtractionResult(text), { questions: [{ question: "Why?" }] });
	}
	for (const text of ['{"questions":[1]}', '{"questions":[{"question":false}]}', '{"questions":[{"question":" "}]}', '{"questions":[{"question":"Why?","context":4}]}', 'garbage']) {
		assert.equal(parseExtractionResult(text), null);
	}
	assert.deepEqual(parseExtractionResult('{"questions":[]}'), { questions: [] });
	assert.deepEqual(parseExtractionResult('{"questions":[{"question":"Why?\nHow?"}]}'), { questions: [{ question: "Why?\nHow?" }] });
});

test("extraction model selection respects scope, auth, and current provider", async () => {
	const current = { provider: "local", id: "main" }, other = { provider: "other", id: "flash-model" }, fast = { provider: "local", id: "main-mini" };
	const registry = { getAvailable: () => [other, fast], getApiKeyAndHeaders: async () => ({ ok: true }) };
	assert.equal(await selectExtractionModel(current, registry), fast);
	assert.equal(await selectExtractionModel(current, registry, [{ model: current }]), current);
	registry.getApiKeyAndHeaders = async () => ({ ok: false });
	assert.equal(await selectExtractionModel(current, registry), current);
});

test("answer command distinguishes provider/parse errors from cancellation", async () => {
	for (const scenario of ["error", "invalid", "aborted", "auth", "empty"]) {
		const commands = new Map(), notices = [];
		answerExtension({ registerCommand: (name, cmd) => commands.set(name, cmd), registerShortcut() {} });
		const model = { provider: "local", id: "main" };
		const ctx = {
			mode: "tui", hasUI: true, model, scopedModels: [{ model }],
			sessionManager: { getBranch: () => [{ type: "message", message: { role: "assistant", stopReason: "stop", content: [{ type: "text", text: "Why?" }] } }] },
			modelRegistry: { complete: async () => {
				if (scenario === "auth") throw new Error("Authentication failed");
				return { stopReason: ["error", "aborted"].includes(scenario) ? scenario : "stop", errorMessage: "Provider failed", content: [{ type: "text", text: scenario === "empty" ? '{"questions":[]}' : "invalid" }] };
			} },
			ui: {
				notify: (text, kind) => notices.push({ text, kind }),
				custom: (factory) => new Promise((resolve) => {
					let component;
					component = factory({ requestRender() {} }, { fg: (_, text) => text }, {}, (value) => { component?.dispose?.(); resolve(value); });
				}),
			},
		};
		await commands.get("answer").handler("", ctx);
		assert.equal(notices.at(-1).kind, ["aborted", "empty"].includes(scenario) ? "info" : "error");
		assert.match(notices.at(-1).text, scenario === "aborted" ? /Cancelled/ : scenario === "empty" ? /No questions/ : /failed/i);
	}
});

test("notifications strip terminal sequences and normalize multiline markdown", () => {
	assert.equal(formatNotification(null).body, "");
	assert.equal(formatNotification("hello\nworld").body, "hello world");
	const { body } = formatNotification('[link](https://example.com)\n\x1b[31mred\x1b[0m\x07');
	assert.match(body, /link/);
	assert.doesNotMatch(body, /[\x00-\x1f\x7f-\x9f]/);
	assert.ok(formatNotification("x".repeat(500)).body.length <= 200);
});

function breakdownData() {
	const now = new Date(2026, 8, 9, 12);
	const ranges = new Map([7, 30, 90].map((days) => [days, buildRangeAgg(days, now)]));
	for (const range of ranges.values()) addSessionToRange(range, {
		dayKeyLocal: range.days.at(-1).dayKeyLocal, cwd: "/project", dow: "Wed", tod: "afternoon",
		modelsUsed: new Set(["a/model", "b/model"]), messages: 3, tokens: 30, totalCost: 3,
		messagesByModel: new Map([["a/model", 1], ["b/model", 2]]), tokensByModel: new Map([["a/model", 10], ["b/model", 20]]), costByModel: new Map([["a/model", 1], ["b/model", 2]]),
	});
	return {
		ranges, generatedAt: now, palette: choosePaletteFromLast30Days(ranges.get(30)), groupedPalette: choosePaletteFromLast30Days(ranges.get(30), 4, true),
		cwdPalette: { cwdColors: new Map(), orderedCwds: [], otherColor: { r: 1, g: 1, b: 1 } },
		dowPalette: { dowColors: new Map(), orderedDows: [] }, todPalette: { todColors: new Map(), orderedTods: [] },
	};
}

test("provider grouping deduplicates sessions and sums usage and cost", () => {
	const range = breakdownData().ranges.get(30);
	assert.equal(range.groupedModelSessions.get("model"), 1);
	assert.equal(range.groupedModelMessages.get("model"), 3);
	assert.equal(range.groupedModelTokens.get("model"), 30);
	assert.equal(range.groupedModelCost.get("model"), 3);
	assert.equal(range.days.at(-1).groupedSessionsByModel.get("model"), 1);
	assert.match(renderModelTable(range, "sessions", 8, true).join("\n"), /cost\/s/);
	assert.match(renderModelTable(range, "sessions", 8, true).at(-1), /\$3\.00\s+\$3\.00\s+100%/);
});

test("statistics fit terminal bounds across views, metrics, and resizing", () => {
	const tui = { terminal: { rows: 40 }, requestRender() {} };
	const component = new BreakdownComponent(breakdownData(), tui, () => {});
	for (const width of [24, 60, 120]) for (const rows of [12, 20, 40]) {
		tui.terminal.rows = rows;
		for (let view = 0; view < 4; view++) {
			for (let metric = 0; metric < 3; metric++) {
				const lines = component.render(width);
				assert.ok(lines.length <= rows);
				assert.ok(lines.every((line) => visibleWidth(line) <= width));
				component.handleInput("t");
			}
			component.handleInput("j");
		}
	}
	component.handleInput("p");
	assert.match(stripTerminalSequences(component.render(120).join("\n")), /split/);
});

test("prompt editor preserves bash labels and wide mode names without overflow", () => {
	const tui = { terminal: { columns: 120, rows: 40 }, requestRender() {} };
	const theme = { borderColor: (text) => text, selectList: { selectedPrefix: (text) => text, selectedText: (text) => text, description: (text) => text, scrollInfo: (text) => text, noMatch: (text) => text } };
	const editor = new PromptEditor(tui, theme, new KeybindingsManager(TUI_KEYBINDINGS));
	editor.modeLabelProvider = () => "\u7814\u7a76\u6a21\u5f0f";
	for (const text of ["hello", "!pwd"]) {
		editor.setText(text);
		for (const width of [12, 24, 80]) {
			const lines = editor.render(width);
			assert.ok(lines.every((line) => visibleWidth(line) <= width));
			if (text.startsWith("!") && width >= 24) assert.match(stripTerminalSequences(lines[0]), /bash/);
		}
	}
	editor.setWorkingStatusIndicator({ renderInBorder: () => "Working", renderSpinnerInBorder: () => "*" });
	editor.setText("hello");
	assert.match(stripTerminalSequences(editor.render(80)[0]), /Working/);
	editor.setText(Array.from({ length: 100 }, (_, i) => `line ${i}`).join("\n"));
	const scrolled = editor.render(80);
	assert.match(stripTerminalSequences(scrolled[0]), /more/);
	assert.ok(scrolled.every((line) => visibleWidth(line) <= 80));
});

test("prompt editor retains local max thinking and non-persistent mode selection", () => {
	const source = readFileSync(new URL("../extensions/prompt-editor.ts", import.meta.url), "utf8");
	assert.match(source, /"xhigh", "max"/);
	assert.match(source, /computeModesPatch\(runtime.baseline, runtime.data, false\)/);
	assert.doesNotMatch(source, /applyMode\(pi, ctx, runtime.data.currentMode\)/);
});

test("Pi loads updated extensions, prompts, and Apple Mail skill without collisions or model calls", async () => {
	const temp = mkdtempSync(join(tmpdir(), "pi-integration-test-"));
	try {
		const extensions = ["goal", "answer", "notify", "prompt-editor", "session-breakdown"];
		const loader = new DefaultResourceLoader({
			cwd: temp, agentDir: temp, settingsManager: SettingsManager.inMemory({ packages: [] }),
			noExtensions: true, noSkills: true, noThemes: true, noContextFiles: true, noPromptTemplates: true,
			additionalExtensionPaths: extensions.map((name) => new URL(`../extensions/${name}.ts`, import.meta.url).pathname),
			additionalPromptTemplatePaths: ["implement", "discuss"].map((name) => new URL(`../prompts/${name}.md`, import.meta.url).pathname),
			additionalSkillPaths: [new URL("../skills/apple-mail", import.meta.url).pathname],
		});
		await loader.reload();
		const loaded = loader.getExtensions();
		assert.deepEqual(loaded.errors, []);
		assert.equal(loaded.extensions.length, extensions.length);
		const prompts = loader.getPrompts();
		assert.deepEqual(prompts.diagnostics, []);
		assert.deepEqual(prompts.prompts.map((p) => p.name).sort(), ["discuss", "implement"]);
		const skills = loader.getSkills();
		assert.deepEqual(skills.diagnostics, []);
		assert.deepEqual(skills.skills.map((skill) => skill.name), ["apple-mail"]);
		const tools = loaded.extensions.flatMap((extension) => [...extension.tools.keys()]);
		assert.equal(tools.length, new Set(tools).size);
		assert.deepEqual(tools.sort(), ["create_goal", "get_goal", "update_goal"]);
		const commands = loaded.extensions.flatMap((extension) => [...extension.commands.keys()]);
		assert.equal(commands.length, new Set(commands).size);
		assert.equal(loaded.extensions.some((extension) => extension.handlers.has("project_trust")), false);
	} finally {
		rmSync(temp, { recursive: true, force: true });
	}
});
