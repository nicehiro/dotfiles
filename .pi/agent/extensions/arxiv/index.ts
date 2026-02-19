import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateHead, DEFAULT_MAX_BYTES, DEFAULT_MAX_LINES, formatSize } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import { XMLParser } from "fast-xml-parser";

const ARXIV_API = "http://export.arxiv.org/api/query";

interface Paper {
	id: string;
	title: string;
	authors: string[];
	abstract: string;
	published: string;
	updated: string;
	categories: string[];
	primaryCategory: string;
	pdfUrl: string;
	absUrl: string;
	comment?: string;
	journalRef?: string;
}

function parseEntry(entry: any): Paper {
	const links = Array.isArray(entry.link) ? entry.link : [entry.link];
	const pdfLink = links.find((l: any) => l["@_type"] === "application/pdf");
	const absLink = links.find((l: any) => l["@_rel"] === "alternate");

	const rawId: string = typeof entry.id === "string" ? entry.id : entry.id?.["#text"] ?? "";
	const shortId = rawId.replace("http://arxiv.org/abs/", "");

	const authors = Array.isArray(entry.author)
		? entry.author.map((a: any) => a.name)
		: entry.author?.name
			? [entry.author.name]
			: [];

	const categories = Array.isArray(entry.category)
		? entry.category.map((c: any) => c["@_term"])
		: entry.category?.["@_term"]
			? [entry.category["@_term"]]
			: [];

	const title = String(entry.title ?? "").replace(/\s+/g, " ").trim();
	const abstract = String(entry.summary ?? "").replace(/\s+/g, " ").trim();

	return {
		id: shortId,
		title,
		authors,
		abstract,
		published: entry.published ?? "",
		updated: entry.updated ?? "",
		categories,
		primaryCategory: entry["arxiv:primary_category"]?.["@_term"] ?? categories[0] ?? "",
		pdfUrl: pdfLink?.["@_href"] ?? `https://arxiv.org/pdf/${shortId}`,
		absUrl: absLink?.["@_href"] ?? `https://arxiv.org/abs/${shortId}`,
		comment: entry["arxiv:comment"] ?? undefined,
		journalRef: entry["arxiv:journal_ref"] ?? undefined,
	};
}

function parseFeed(xml: string): { papers: Paper[]; totalResults: number } {
	const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: "@_" });
	const doc = parser.parse(xml);
	const feed = doc.feed;
	if (!feed) throw new Error("Invalid arXiv API response");

	const totalResults = parseInt(feed["opensearch:totalResults"]?.["#text"] ?? feed["opensearch:totalResults"] ?? "0");
	const entries = feed.entry ? (Array.isArray(feed.entry) ? feed.entry : [feed.entry]) : [];

	return { papers: entries.map(parseEntry), totalResults };
}

function formatPaper(p: Paper, index?: number): string {
	const prefix = index !== undefined ? `[${index + 1}] ` : "";
	const lines = [
		`${prefix}${p.title}`,
		`    ID: ${p.id}`,
		`    Authors: ${p.authors.join(", ")}`,
		`    Published: ${p.published.slice(0, 10)}  Updated: ${p.updated.slice(0, 10)}`,
		`    Categories: ${p.categories.join(", ")}`,
		`    PDF: ${p.pdfUrl}`,
	];
	if (p.comment) lines.push(`    Comment: ${p.comment}`);
	if (p.journalRef) lines.push(`    Journal: ${p.journalRef}`);
	lines.push(`    Abstract: ${p.abstract}`);
	return lines.join("\n");
}

interface SearchDetails {
	query: string;
	totalResults: number;
	returned: number;
	papers: Paper[];
}

interface PaperDetails {
	paper: Paper | null;
}

async function fetchArxiv(url: string, signal?: AbortSignal): Promise<string> {
	const resp = await fetch(url, { signal });
	if (!resp.ok) throw new Error(`arXiv API error: ${resp.status} ${resp.statusText}`);
	return resp.text();
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "arxiv_search",
		label: "arXiv Search",
		description:
			"Search arXiv papers. Supports query terms, category filters (cs.RO, cs.LG, cs.CV, cs.AI, cs.CL, stat.ML, etc.), and sorting. Returns titles, authors, abstracts, dates, and PDF links.",
		parameters: Type.Object({
			query: Type.String({ description: 'Search query, e.g. "vision language action model"' }),
			category: Type.Optional(
				Type.String({ description: "arXiv category filter, e.g. cs.RO, cs.LG, cs.CV" })
			),
			max_results: Type.Optional(
				Type.Number({ description: "Max papers to return (default 10, max 50)", default: 10 })
			),
			sort_by: Type.Optional(
				StringEnum(["relevance", "lastUpdatedDate", "submittedDate"] as const, {
					description: "Sort order (default: relevance)",
				})
			),
			start: Type.Optional(
				Type.Number({ description: "Start index for pagination (default 0)", default: 0 })
			),
		}),

		async execute(_toolCallId, params, signal) {
			const maxResults = Math.min(params.max_results ?? 10, 50);
			const start = params.start ?? 0;

			let searchQuery = `all:${params.query}`;
			if (params.category) {
				searchQuery = `cat:${params.category}+AND+${searchQuery}`;
			}

			const sortParam = params.sort_by ?? "relevance";
			const url =
				`${ARXIV_API}?search_query=${encodeURIComponent(searchQuery)}` +
				`&start=${start}&max_results=${maxResults}` +
				`&sortBy=${sortParam}&sortOrder=descending`;

			const xml = await fetchArxiv(url, signal);
			const { papers, totalResults } = parseFeed(xml);

			if (papers.length === 0) {
				return {
					content: [{ type: "text", text: `No papers found for query: ${params.query}` }],
					details: { query: params.query, totalResults: 0, returned: 0, papers: [] } as SearchDetails,
				};
			}

			const header = `Found ${totalResults} papers (showing ${start + 1}-${start + papers.length}):\n`;
			const body = papers.map((p, i) => formatPaper(p, i)).join("\n\n");
			let text = header + body;

			const truncation = truncateHead(text, { maxLines: DEFAULT_MAX_LINES, maxBytes: DEFAULT_MAX_BYTES });
			text = truncation.content;
			if (truncation.truncated) {
				text += `\n\n[Output truncated: ${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}]`;
			}

			return {
				content: [{ type: "text", text }],
				details: { query: params.query, totalResults, returned: papers.length, papers } as SearchDetails,
			};
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("arxiv "));
			text += theme.fg("accent", `"${args.query}"`);
			if (args.category) text += theme.fg("muted", ` cat:${args.category}`);
			if (args.max_results) text += theme.fg("dim", ` max:${args.max_results}`);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as SearchDetails | undefined;
			if (!details || details.returned === 0) {
				return new Text(theme.fg("dim", "No papers found"), 0, 0);
			}

			let text = theme.fg("success", `${details.totalResults} results`);
			text += theme.fg("dim", ` (showing ${details.returned})`);

			if (expanded) {
				for (const p of details.papers) {
					text += "\n\n" + theme.fg("accent", theme.bold(p.title));
					text += "\n" + theme.fg("dim", `${p.id} · ${p.published.slice(0, 10)} · ${p.authors.slice(0, 3).join(", ")}${p.authors.length > 3 ? " et al." : ""}`);
				}
			}

			return new Text(text, 0, 0);
		},
	});

	pi.registerTool({
		name: "arxiv_paper",
		label: "arXiv Paper",
		description:
			"Fetch details of a specific arXiv paper by ID. Accepts arXiv IDs like '2401.12345' or '2401.12345v2', or full URLs like 'https://arxiv.org/abs/2401.12345'.",
		parameters: Type.Object({
			id: Type.String({ description: 'arXiv paper ID, e.g. "2401.12345" or full arXiv URL' }),
		}),

		async execute(_toolCallId, params, signal) {
			let paperId = params.id.replace(/^@/, "");
			paperId = paperId.replace(/^https?:\/\/arxiv\.org\/(abs|pdf)\//, "");
			paperId = paperId.replace(/\.pdf$/, "");

			const url = `${ARXIV_API}?id_list=${encodeURIComponent(paperId)}`;
			const xml = await fetchArxiv(url, signal);
			const { papers } = parseFeed(xml);

			if (papers.length === 0 || !papers[0].title) {
				return {
					content: [{ type: "text", text: `Paper not found: ${paperId}` }],
					details: { paper: null } as PaperDetails,
					isError: true,
				};
			}

			const paper = papers[0];
			return {
				content: [{ type: "text", text: formatPaper(paper) }],
				details: { paper } as PaperDetails,
			};
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("arxiv "));
			text += theme.fg("accent", args.id);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as PaperDetails | undefined;
			if (!details?.paper) {
				return new Text(theme.fg("error", "Paper not found"), 0, 0);
			}

			const p = details.paper;
			let text = theme.fg("accent", theme.bold(p.title));
			text += "\n" + theme.fg("dim", `${p.id} · ${p.published.slice(0, 10)}`);
			text += "\n" + theme.fg("muted", p.authors.join(", "));

			if (expanded) {
				text += "\n" + theme.fg("dim", `Categories: ${p.categories.join(", ")}`);
				if (p.comment) text += "\n" + theme.fg("dim", `Comment: ${p.comment}`);
				if (p.journalRef) text += "\n" + theme.fg("dim", `Journal: ${p.journalRef}`);
				text += "\n\n" + p.abstract;
			}

			return new Text(text, 0, 0);
		},
	});
}
