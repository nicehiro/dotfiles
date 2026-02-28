import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateHead, DEFAULT_MAX_BYTES, DEFAULT_MAX_LINES, formatSize } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text } from "@mariozechner/pi-tui";
import { readFileSync } from "node:fs";

const BBT_URL = "http://localhost:23119/better-bibtex/json-rpc";
const BIBTEX_PATH = process.env.BIBTEX_PATH;

interface CSLItem {
	id: string;
	type: string;
	title?: string;
	"title-short"?: string;
	abstract?: string;
	"citation-key"?: string;
	citekey?: string;
	URL?: string;
	DOI?: string;
	author?: { family: string; given: string }[];
	issued?: { "date-parts": (string | number)[][] };
	"container-title"?: string;
	library?: string;
}

interface Attachment {
	open: string;
	path: string;
	annotations?: {
		annotationType: string;
		annotationText: string;
		annotationComment: string;
		annotationColor: string;
		annotationPageLabel: string;
	}[];
}

async function bbtCall(method: string, params: unknown[]): Promise<unknown> {
	const res = await fetch(BBT_URL, {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({ jsonrpc: "2.0", method, params, id: 1 }),
	});
	const data = (await res.json()) as { result?: unknown; error?: { message: string } };
	if (data.error) throw new Error(`BBT: ${data.error.message}`);
	return data.result;
}

async function isBBTAvailable(): Promise<boolean> {
	try {
		const res = await fetch(BBT_URL, {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ jsonrpc: "2.0", method: "item.search", params: ["__ping__"], id: 0 }),
			signal: AbortSignal.timeout(2000),
		});
		return res.ok;
	} catch {
		return false;
	}
}

function formatAuthor(a: { family: string; given: string }): string {
	return `${a.family}, ${a.given}`;
}

function formatYear(item: CSLItem): string {
	const parts = item.issued?.["date-parts"]?.[0];
	return parts?.[0]?.toString() ?? "n.d.";
}

function formatItemCompact(item: CSLItem): string {
	const key = item.citekey ?? item["citation-key"] ?? "?";
	const year = formatYear(item);
	const authors = item.author?.map((a) => a.family).join(", ") ?? "Unknown";
	return `[${key}] ${authors} (${year}). ${item.title}`;
}

function formatItemFull(item: CSLItem): string {
	const key = item.citekey ?? item["citation-key"] ?? "?";
	const year = formatYear(item);
	const authors = item.author?.map(formatAuthor).join("; ") ?? "Unknown";
	const lines = [
		`Cite key: ${key}`,
		`Title: ${item.title}`,
		`Authors: ${authors}`,
		`Year: ${year}`,
	];
	if (item.type) lines.push(`Type: ${item.type}`);
	if (item["container-title"]) lines.push(`Venue: ${item["container-title"]}`);
	if (item.DOI) lines.push(`DOI: ${item.DOI}`);
	if (item.URL) lines.push(`URL: ${item.URL}`);
	if (item.abstract) lines.push(`Abstract: ${item.abstract}`);
	return lines.join("\n");
}

// Fallback: search BibTeX file directly
function searchBibtex(query: string, maxResults: number): string[] {
	if (!BIBTEX_PATH) throw new Error("BIBTEX_PATH not set. Export it in your shell to enable offline BibTeX search.");
	const content = readFileSync(BIBTEX_PATH, "utf-8");
	const entries = content.split(/(?=^@)/m).filter((e) => e.trim());
	const terms = query.toLowerCase().split(/\s+/);
	const matches: string[] = [];
	for (const entry of entries) {
		const lower = entry.toLowerCase();
		if (terms.every((t) => lower.includes(t))) {
			matches.push(entry.trim());
			if (matches.length >= maxResults) break;
		}
	}
	return matches;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "zotero",
		label: "Zotero",
		description: `Search and query the user's Zotero library via Better BibTeX. Actions:
- search: Full-text search across titles, authors, abstracts. Returns matching items with cite keys.
- cite: Get BibTeX entries for specific cite keys. Use after search to get exportable references.
- details: Get full metadata, notes, and PDF annotations for a cite key.
- collections: Get which collections a cite key belongs to.
Falls back to searching the local BibTeX file (~474 entries) if Zotero is not running.`,
		parameters: Type.Object({
			action: StringEnum(["search", "cite", "details", "collections"] as const),
			query: Type.Optional(Type.String({ description: "Search terms (for search action)" })),
			citekeys: Type.Optional(
				Type.Array(Type.String(), { description: "Citation keys (for cite/details/collections)" })
			),
			max_results: Type.Optional(
				Type.Number({ description: "Max results for search (default 10)", default: 10 })
			),
		}),

		async execute(_toolCallId, params, _signal) {
			const { action, query, citekeys, max_results = 10 } = params;

			try {
				if (action === "search") {
					if (!query) return err("query is required for search action");

					const online = await isBBTAvailable();
					if (online) {
						const items = (await bbtCall("item.search", [query])) as CSLItem[];
						if (items.length === 0) return ok("No items found in Zotero library.");
						const limited = items.slice(0, max_results);
						const lines = limited.map(formatItemCompact);
						const header = `Found ${items.length} item(s)${items.length > max_results ? ` (showing first ${max_results})` : ""}:\n`;
						return ok(header + lines.join("\n"));
					} else {
						const matches = searchBibtex(query, max_results);
						if (matches.length === 0) return ok("No items found in BibTeX file.");
						const header = `[Zotero offline — searched BibTeX file directly]\nFound ${matches.length} match(es):\n\n`;
						const text = header + matches.join("\n\n");
						return truncated(text);
					}
				}

				if (action === "cite") {
					if (!citekeys?.length) return err("citekeys required for cite action");
					const online = await isBBTAvailable();
					if (online) {
						const bibtex = (await bbtCall("item.export", [citekeys, "betterbibtex"])) as string;
						if (!bibtex.trim()) return ok("No BibTeX entries found for the given cite keys.");
						return truncated(bibtex);
					} else {
						if (!BIBTEX_PATH) return err("BIBTEX_PATH not set. Export it in your shell to enable offline BibTeX fallback.");
						const content = readFileSync(BIBTEX_PATH, "utf-8");
						const entries = content.split(/(?=^@)/m).filter((e) => e.trim());
						const found: string[] = [];
						for (const key of citekeys) {
							const entry = entries.find((e) => e.includes(`{${key},`) || e.includes(`{${key}\n`));
							if (entry) found.push(entry.trim());
							else found.push(`% Not found: ${key}`);
						}
						return truncated("[Zotero offline — from BibTeX file]\n\n" + found.join("\n\n"));
					}
				}

				if (action === "details") {
					if (!citekeys?.length) return err("citekeys required for details action");
					if (!(await isBBTAvailable())) return err("Zotero is not running. Details requires BBT.");

					const sections: string[] = [];
					for (const key of citekeys) {
						const items = (await bbtCall("item.search", [key])) as CSLItem[];
						const item = items.find(
							(i) => i.citekey === key || i["citation-key"] === key
						);
						if (!item) {
							sections.push(`# ${key}\nNot found.`);
							continue;
						}

						const lines = [
							`# ${key}`,
							formatItemFull(item),
						];

						// Notes
						const notes = (await bbtCall("item.notes", [[key]])) as Record<string, string[]>;
						const itemNotes = notes[key];
						if (itemNotes?.length) {
							lines.push(`\nNotes:\n${itemNotes.join("\n---\n")}`);
						}

						// Attachments & annotations
						const attachments = (await bbtCall("item.attachments", [key])) as Attachment[];
						const pdfs = attachments.filter((a) => a.path.endsWith(".pdf"));
						if (pdfs.length) {
							lines.push(`\nPDF: ${pdfs[0].path}`);
							const allAnnotations = pdfs.flatMap((p) => p.annotations ?? []);
							if (allAnnotations.length) {
								lines.push(`\nAnnotations (${allAnnotations.length}):`);
								for (const ann of allAnnotations) {
									const prefix = ann.annotationType === "highlight" ? "Highlight" : ann.annotationType;
									lines.push(`  [${prefix}, p.${ann.annotationPageLabel}] ${ann.annotationText}`);
									if (ann.annotationComment) {
										lines.push(`    Comment: ${ann.annotationComment}`);
									}
								}
							}
						}

						// Collections
						const colls = (await bbtCall("item.collections", [[key]])) as Record<
							string,
							{ name: string }[]
						>;
						const itemColls = colls[key];
						if (itemColls?.length) {
							lines.push(`\nCollections: ${itemColls.map((c) => c.name).join(", ")}`);
						}

						sections.push(lines.join("\n"));
					}

					return truncated(sections.join("\n\n---\n\n"));
				}

				if (action === "collections") {
					if (!citekeys?.length) return err("citekeys required for collections action");
					if (!(await isBBTAvailable())) return err("Zotero is not running.");

					const colls = (await bbtCall("item.collections", [citekeys])) as Record<
						string,
						{ name: string; parentCollection: boolean | string }[]
					>;
					const lines: string[] = [];
					for (const [key, collections] of Object.entries(colls)) {
						if (collections.length === 0) {
							lines.push(`${key}: (no collections)`);
						} else {
							lines.push(`${key}: ${collections.map((c) => c.name).join(", ")}`);
						}
					}
					return ok(lines.join("\n"));
				}

				return err(`Unknown action: ${action}`);
			} catch (e: unknown) {
				const msg = e instanceof Error ? e.message : String(e);
				return err(msg);
			}
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("zotero "));
			text += theme.fg("accent", args.action ?? "");
			if (args.query) text += " " + theme.fg("dim", `"${args.query}"`);
			if (args.citekeys?.length) text += " " + theme.fg("dim", args.citekeys.join(", "));
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const text = result.content?.[0];
			if (!text || text.type !== "text") return new Text("", 0, 0);

			if (result.isError) return new Text(theme.fg("error", text.text), 0, 0);

			const lines = text.text.split("\n");
			if (!expanded && lines.length > 8) {
				const preview = lines.slice(0, 8).join("\n");
				return new Text(preview + "\n" + theme.fg("muted", `... ${lines.length - 8} more lines`), 0, 0);
			}
			return new Text(text.text, 0, 0);
		},
	});
}

function ok(text: string) {
	return { content: [{ type: "text" as const, text }], details: {} };
}

function err(text: string) {
	return { content: [{ type: "text" as const, text }], details: {}, isError: true };
}

function truncated(text: string) {
	const t = truncateHead(text, { maxLines: DEFAULT_MAX_LINES, maxBytes: DEFAULT_MAX_BYTES });
	let result = t.content;
	if (t.truncated) {
		result += `\n\n[Output truncated: ${t.outputLines} of ${t.totalLines} lines (${formatSize(t.outputBytes)} of ${formatSize(t.totalBytes)})]`;
	}
	return { content: [{ type: "text" as const, text: result }], details: {} };
}
