import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateHead, DEFAULT_MAX_BYTES, DEFAULT_MAX_LINES, formatSize } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

const DEFAULT_BASE_URL = "https://api.wandb.ai";

function getConfig(): { baseUrl: string; apiKey: string | undefined } {
	return {
		baseUrl: process.env.WANDB_BASE_URL ?? DEFAULT_BASE_URL,
		apiKey: process.env.WANDB_API_KEY,
	};
}

async function graphql(query: string, variables: Record<string, any>, signal?: AbortSignal): Promise<any> {
	const { baseUrl, apiKey } = getConfig();
	if (!apiKey) throw new Error("WANDB_API_KEY not set. Export it in your shell.");

	const resp = await fetch(`${baseUrl}/graphql`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Basic ${Buffer.from(`api:${apiKey}`).toString("base64")}`,
		},
		body: JSON.stringify({ query, variables }),
		signal,
	});

	if (!resp.ok) {
		const text = await resp.text().catch(() => "");
		throw new Error(`W&B API error ${resp.status}: ${text}`);
	}

	const json = await resp.json();
	if (json.errors?.length) {
		throw new Error(`W&B GraphQL error: ${json.errors.map((e: any) => e.message).join("; ")}`);
	}
	return json.data;
}

// --- Formatting helpers ---

function formatConfig(config: Record<string, any>): string {
	const skip = new Set(["_wandb", "wandb_version"]);
	return Object.entries(config)
		.filter(([k]) => !skip.has(k))
		.map(([k, v]) => `  ${k}: ${typeof v === "object" ? JSON.stringify(v) : v}`)
		.join("\n");
}

function formatSummary(summary: Record<string, any>): string {
	const skip = new Set(["_wandb", "_runtime", "_step", "_timestamp"]);
	return Object.entries(summary)
		.filter(([k]) => !skip.has(k) && !k.startsWith("_"))
		.map(([k, v]) => `  ${k}: ${typeof v === "number" ? (Number.isInteger(v) ? v : v.toFixed(6)) : v}`)
		.join("\n");
}

function formatRunCompact(run: any): string {
	const config = run.config ? JSON.parse(run.config) : {};
	const summary = run.summaryMetrics ? JSON.parse(run.summaryMetrics) : {};
	const lines = [
		`${run.displayName ?? run.name} (${run.state})`,
		`  ID: ${run.name}  Created: ${run.createdAt}`,
	];
	if (run.tags?.length) lines.push(`  Tags: ${run.tags.join(", ")}`);

	const summaryStr = formatSummary(summary);
	if (summaryStr) lines.push(`  Metrics:\n${summaryStr}`);

	const configStr = formatConfig(config);
	if (configStr) lines.push(`  Config:\n${configStr}`);

	return lines.join("\n");
}

// --- GraphQL queries ---

const RUNS_QUERY = `
query Runs($entity: String!, $project: String!, $filters: JSONString, $order: String, $first: Int) {
  project(name: $project, entityName: $entity) {
    runs(filters: $filters, order: $order, first: $first) {
      edges {
        node {
          name
          displayName
          state
          createdAt
          tags
          config
          summaryMetrics
        }
      }
    }
  }
}`;

const RUN_DETAIL_QUERY = `
query RunDetail($entity: String!, $project: String!, $runName: String!) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      name
      displayName
      state
      createdAt
      heartbeatAt
      tags
      notes
      config
      summaryMetrics
      systemMetrics
    }
  }
}`;

const HISTORY_QUERY = `
query RunHistory($entity: String!, $project: String!, $runName: String!, $samples: Int) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      name
      displayName
      sampledHistory(specs: [{key: "*", samples: $samples}])
    }
  }
}`;

// --- Extension ---

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "wandb_runs",
		label: "W&B Runs",
		description:
			"List runs from a Weights & Biases project. Returns run names, states, summary metrics, and configs. " +
			"Requires WANDB_API_KEY env var.",
		parameters: Type.Object({
			entity: Type.String({ description: "W&B entity (username or team name)" }),
			project: Type.String({ description: "W&B project name" }),
			filters: Type.Optional(
				Type.String({
					description:
						'W&B run filters as JSON string, e.g. \'{"state":"finished"}\' or \'{"tags":{"$in":["baseline"]}}\'',
				})
			),
			order: Type.Optional(
				Type.String({
					description: 'Sort order, e.g. "+created_at", "-summary_metrics.loss" (default: "-created_at")',
				})
			),
			max_results: Type.Optional(
				Type.Number({ description: "Max runs to return (default 20, max 100)", default: 20 })
			),
		}),

		async execute(_toolCallId, params, signal) {
			const first = Math.min(params.max_results ?? 20, 100);
			const data = await graphql(
				RUNS_QUERY,
				{
					entity: params.entity,
					project: params.project,
					filters: params.filters ?? "{}",
					order: params.order ?? "-created_at",
					first,
				},
				signal
			);

			const runs = data.project?.runs?.edges?.map((e: any) => e.node) ?? [];
			if (runs.length === 0) {
				return {
					content: [{ type: "text", text: `No runs found in ${params.entity}/${params.project}` }],
					details: { entity: params.entity, project: params.project, runs: [] },
				};
			}

			const header = `${params.entity}/${params.project}: ${runs.length} runs\n`;
			const body = runs.map((r: any, i: number) => `[${i + 1}] ${formatRunCompact(r)}`).join("\n\n");
			let text = header + body;

			const trunc = truncateHead(text, { maxLines: DEFAULT_MAX_LINES, maxBytes: DEFAULT_MAX_BYTES });
			text = trunc.content;
			if (trunc.truncated) {
				text += `\n\n[Truncated: ${formatSize(trunc.outputBytes)} of ${formatSize(trunc.totalBytes)}]`;
			}

			return {
				content: [{ type: "text", text }],
				details: { entity: params.entity, project: params.project, runs },
			};
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("wandb runs "));
			text += theme.fg("accent", `${args.entity}/${args.project}`);
			if (args.filters) text += theme.fg("dim", ` filters:${args.filters}`);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as any;
			if (!details?.runs?.length) return new Text(theme.fg("dim", "No runs found"), 0, 0);

			let text = theme.fg("success", `${details.runs.length} runs`);
			text += theme.fg("dim", ` in ${details.entity}/${details.project}`);

			if (expanded) {
				for (const r of details.runs) {
					const state = r.state === "finished" ? theme.fg("success", r.state) : theme.fg("warning", r.state);
					text += "\n  " + theme.fg("accent", r.displayName ?? r.name) + " " + state;
				}
			}
			return new Text(text, 0, 0);
		},
	});

	pi.registerTool({
		name: "wandb_run",
		label: "W&B Run",
		description:
			"Get full details of a specific W&B run including config, summary metrics, notes, and system metrics. " +
			"Requires WANDB_API_KEY env var.",
		parameters: Type.Object({
			entity: Type.String({ description: "W&B entity (username or team name)" }),
			project: Type.String({ description: "W&B project name" }),
			run_id: Type.String({ description: "Run ID (the short alphanumeric ID, not display name)" }),
		}),

		async execute(_toolCallId, params, signal) {
			const data = await graphql(
				RUN_DETAIL_QUERY,
				{ entity: params.entity, project: params.project, runName: params.run_id },
				signal
			);

			const run = data.project?.run;
			if (!run) {
				return {
					content: [{ type: "text", text: `Run not found: ${params.run_id}` }],
					details: { run: null },
					isError: true,
				};
			}

			const config = run.config ? JSON.parse(run.config) : {};
			const summary = run.summaryMetrics ? JSON.parse(run.summaryMetrics) : {};

			const lines = [
				`Run: ${run.displayName ?? run.name} (${run.state})`,
				`ID: ${run.name}`,
				`Created: ${run.createdAt}`,
				`Last heartbeat: ${run.heartbeatAt}`,
			];
			if (run.tags?.length) lines.push(`Tags: ${run.tags.join(", ")}`);
			if (run.notes) lines.push(`Notes: ${run.notes}`);

			const summaryStr = formatSummary(summary);
			if (summaryStr) lines.push(`\nSummary Metrics:\n${summaryStr}`);

			const configStr = formatConfig(config);
			if (configStr) lines.push(`\nConfig:\n${configStr}`);

			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: { run, config, summary },
			};
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("wandb run "));
			text += theme.fg("accent", `${args.entity}/${args.project}/${args.run_id}`);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as any;
			if (!details?.run) return new Text(theme.fg("error", "Run not found"), 0, 0);

			const r = details.run;
			const state = r.state === "finished" ? theme.fg("success", r.state) : theme.fg("warning", r.state);
			let text = theme.fg("accent", theme.bold(r.displayName ?? r.name)) + " " + state;

			if (expanded) {
				const summary = details.summary ?? {};
				for (const [k, v] of Object.entries(summary)) {
					if (k.startsWith("_")) continue;
					text += "\n  " + theme.fg("dim", `${k}: ${typeof v === "number" ? (Number.isInteger(v) ? v : (v as number).toFixed(6)) : v}`);
				}
			}
			return new Text(text, 0, 0);
		},
	});

	pi.registerTool({
		name: "wandb_history",
		label: "W&B History",
		description:
			"Get metric history (training curves) for a W&B run. Returns sampled datapoints for specified metrics over training steps. " +
			"Useful for analyzing loss curves, learning rates, and evaluation metrics over time. " +
			"Requires WANDB_API_KEY env var.",
		parameters: Type.Object({
			entity: Type.String({ description: "W&B entity (username or team name)" }),
			project: Type.String({ description: "W&B project name" }),
			run_id: Type.String({ description: "Run ID" }),
			samples: Type.Optional(
				Type.Number({ description: "Number of sampled datapoints to return (default 500, max 10000)", default: 500 })
			),
		}),

		async execute(_toolCallId, params, signal) {
			const samples = Math.min(params.samples ?? 500, 10000);
			const data = await graphql(
				HISTORY_QUERY,
				{ entity: params.entity, project: params.project, runName: params.run_id, samples },
				signal
			);

			const run = data.project?.run;
			if (!run) {
				return {
					content: [{ type: "text", text: `Run not found: ${params.run_id}` }],
					details: { run: null, history: [] },
					isError: true,
				};
			}

			const history: Record<string, any>[] = run.sampledHistory?.[0] ?? [];
			if (history.length === 0) {
				return {
					content: [{ type: "text", text: `No history data for run ${params.run_id}` }],
					details: { run: { name: run.name, displayName: run.displayName }, history: [] },
				};
			}

			// Collect all metric keys
			const keys = new Set<string>();
			for (const row of history) {
				for (const k of Object.keys(row)) {
					if (!k.startsWith("_")) keys.add(k);
				}
			}
			const sortedKeys = Array.from(keys).sort();

			// Build table header
			const header = `Run: ${run.displayName ?? run.name} (${history.length} samples)\n`;
			const colHeader = ["_step", ...sortedKeys].join("\t");

			// Build rows
			const rows = history.map((row) => {
				const step = row._step ?? "";
				const vals = sortedKeys.map((k) => {
					const v = row[k];
					if (v === undefined || v === null) return "";
					if (typeof v === "number") return Number.isInteger(v) ? String(v) : v.toFixed(6);
					return String(v);
				});
				return [step, ...vals].join("\t");
			});

			let text = header + colHeader + "\n" + rows.join("\n");

			const trunc = truncateHead(text, { maxLines: DEFAULT_MAX_LINES, maxBytes: DEFAULT_MAX_BYTES });
			text = trunc.content;
			if (trunc.truncated) {
				text += `\n\n[Truncated: ${formatSize(trunc.outputBytes)} of ${formatSize(trunc.totalBytes)}]`;
			}

			return {
				content: [{ type: "text", text }],
				details: {
					run: { name: run.name, displayName: run.displayName },
					history,
					keys: sortedKeys,
				},
			};
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("wandb history "));
			text += theme.fg("accent", `${args.entity}/${args.project}/${args.run_id}`);
			if (args.samples) text += theme.fg("dim", ` samples:${args.samples}`);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as any;
			if (!details?.run) return new Text(theme.fg("error", "Run not found"), 0, 0);

			const history = details.history ?? [];
			const keys = details.keys ?? [];
			let text = theme.fg("accent", theme.bold(details.run.displayName ?? details.run.name));
			text += theme.fg("dim", ` ${history.length} datapoints, ${keys.length} metrics`);

			if (expanded && keys.length) {
				text += "\n" + theme.fg("dim", `Metrics: ${keys.join(", ")}`);
				if (history.length > 0) {
					const last = history[history.length - 1];
					text += "\n" + theme.fg("muted", "Latest:");
					for (const k of keys) {
						if (last[k] !== undefined) {
							const v = typeof last[k] === "number" ? (Number.isInteger(last[k]) ? last[k] : last[k].toFixed(6)) : last[k];
							text += `\n  ${k}: ${v}`;
						}
					}
				}
			}
			return new Text(text, 0, 0);
		},
	});
}
