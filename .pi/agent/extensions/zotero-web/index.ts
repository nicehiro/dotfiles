import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text } from "@mariozechner/pi-tui";

interface ZoteroConfig {
  apiKey: string;
  userId: string;
  baseUrl?: string;
}

interface ZoteroCreator {
  firstName?: string;
  lastName?: string;
  name?: string;
}

interface ZoteroItemSummary {
  key: string;
  version: number;
  itemType: string;
  title: string;
  creators: ZoteroCreator[];
  year?: number;
  tags: string[];
  collections: string[];
}

interface ZoteroItem extends ZoteroItemSummary {
  raw: any;
}

interface ZoteroCollection {
  key: string;
  name: string;
  parentCollection?: string | null;
  itemCount?: number;
}

interface ZoteroTag {
  tag: string;
  type?: number;
  numItems?: number;
}

interface SearchItemsParams {
  query?: string;
  tag?: string;
  collectionKey?: string;
  itemType?: string;
  limit?: number;
  sort?: "title" | "dateAdded" | "dateModified" | "creator" | "year";
  direction?: "asc" | "desc";
}

interface GetCollectionItemsParams {
  collectionKey: string;
  full?: boolean;
  limit?: number;
}

interface GetCitationParams {
  keys: string[];
  format: "bibtex" | "csljson" | "formatted";
  style?: string;
  locale?: string;
}

interface ModifyTagsParams {
  itemKeys: string[];
  tags: string[];
}

interface ModifyCollectionsParams {
  itemKeys: string[];
  collectionKeys: string[];
}

interface CreateCollectionParams {
  name: string;
  parentCollectionKey?: string;
}

class ZoteroWebClient {
  private baseUrl: string;

  constructor(private config: ZoteroConfig) {
    this.baseUrl = (config.baseUrl ?? "https://api.zotero.org").replace(/\/$/, "");
  }

  private buildUrl(path: string, query?: Record<string, any>): string {
    const url = new URL(this.baseUrl + "/" + path.replace(/^\/+/, ""));
    if (query) {
      for (const [k, v] of Object.entries(query)) {
        if (v === undefined || v === null) continue;
        url.searchParams.set(k, String(v));
      }
    }
    return url.toString();
  }

  private async requestJson<T>(
    path: string,
    query?: Record<string, any>,
    init: { method?: string; body?: any; signal?: AbortSignal } = {},
  ): Promise<T> {
    const res = await fetch(this.buildUrl(path, query), {
      method: init.method ?? "GET",
      headers: {
        "Zotero-API-Key": this.config.apiKey,
        "Zotero-API-Version": "3",
        Accept: "application/json",
        ...(init.body ? { "Content-Type": "application/json" } : {}),
      },
      body: init.body ? JSON.stringify(init.body) : undefined,
      signal: init.signal,
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`Zotero API error ${res.status}: ${text}`);
    }

    return (await res.json()) as T;
  }

  private async requestJsonPaginated<T>(
    path: string,
    query?: Record<string, any>,
    init: { signal?: AbortSignal } = {},
  ): Promise<T[]> {
    const PAGE_SIZE = 100;
    const results: T[] = [];
    let start = 0;
    let total = Infinity;

    while (start < total) {
      const q = { ...query, format: "json", limit: PAGE_SIZE, start };
      const res = await fetch(this.buildUrl(path, q), {
        method: "GET",
        headers: {
          "Zotero-API-Key": this.config.apiKey,
          "Zotero-API-Version": "3",
          Accept: "application/json",
        },
        signal: init.signal,
      });

      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`Zotero API error ${res.status}: ${text}`);
      }

      const totalHeader = res.headers.get("Total-Results");
      if (totalHeader !== null) total = parseInt(totalHeader, 10);

      const page = (await res.json()) as T[];
      results.push(...page);

      if (page.length < PAGE_SIZE) break;
      start += PAGE_SIZE;
    }

    return results;
  }

  private async requestText(
    path: string,
    query?: Record<string, any>,
    init: { method?: string; body?: any; signal?: AbortSignal } = {},
  ): Promise<string> {
    const res = await fetch(this.buildUrl(path, query), {
      method: init.method ?? "GET",
      headers: {
        "Zotero-API-Key": this.config.apiKey,
        "Zotero-API-Version": "3",
        ...(init.body ? { "Content-Type": "application/json" } : {}),
      },
      body: init.body ? JSON.stringify(init.body) : undefined,
      signal: init.signal,
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`Zotero API error ${res.status}: ${text}`);
    }

    return await res.text();
  }

  private mapItem(raw: any): ZoteroItem {
    const data = raw.data ?? raw;
    const creators: ZoteroCreator[] = Array.isArray(data.creators) ? data.creators : [];
    const tags: string[] = Array.isArray(data.tags) ? data.tags.map((t: any) => t.tag).filter(Boolean) : [];
    const collections: string[] = Array.isArray(data.collections) ? data.collections : [];

    let year: number | undefined;
    if (typeof data.date === "string") {
      const m = data.date.match(/(\d{4})/);
      if (m) year = parseInt(m[1], 10);
    }

    return {
      key: raw.key ?? data.key,
      version: raw.version ?? data.version ?? 0,
      itemType: data.itemType,
      title: data.title ?? "",
      creators,
      year,
      tags,
      collections,
      raw: data,
    };
  }

  private mapItemSummary(raw: any): ZoteroItemSummary {
    const item = this.mapItem(raw);
    const { raw: _raw, ...summary } = item;
    return summary;
  }

  async searchItems(params: SearchItemsParams, signal?: AbortSignal): Promise<ZoteroItemSummary[]> {
    const query: Record<string, any> = { format: "json" };
    if (params.limit !== undefined) query.limit = params.limit;
    if (params.query) {
      query.q = params.query;
      query.qmode = "titleCreatorYear";
    }
    if (params.tag) query.tag = params.tag;
    if (params.collectionKey) query.collection = params.collectionKey;
    if (params.itemType) query.itemType = params.itemType;
    if (params.sort) query.sort = params.sort;
    if (params.direction) query.direction = params.direction;

    const rawItems = await this.requestJson<any[]>(`users/${this.config.userId}/items`, query, { signal });
    return rawItems.map((r) => this.mapItemSummary(r));
  }

  async getItemByKey(key: string, signal?: AbortSignal): Promise<ZoteroItem | null> {
    const raw = await this.requestJson<any>(`users/${this.config.userId}/items/${key}`, { format: "json" }, { signal });
    if (!raw) return null;
    return this.mapItem(raw);
  }

  async getItemsByKeys(keys: string[], signal?: AbortSignal): Promise<ZoteroItem[]> {
    if (!keys.length) return [];
    const query: Record<string, any> = {
      format: "json",
      itemKey: keys.join(","),
    };
    const rawItems = await this.requestJson<any[]>(`users/${this.config.userId}/items`, query, { signal });
    return rawItems.map((r) => this.mapItem(r));
  }

  async getItemByDOI(doi: string, signal?: AbortSignal): Promise<ZoteroItem | null> {
    const query: Record<string, any> = {
      format: "json",
      q: doi,
      qmode: "everything",
    };
    const rawItems = await this.requestJson<any[]>(`users/${this.config.userId}/items`, query, { signal });
    const match = rawItems.find((r) => {
      const data = r.data ?? r;
      return typeof data.DOI === "string" && data.DOI.toLowerCase() === doi.toLowerCase();
    });
    return match ? this.mapItem(match) : null;
  }

  async getItemByCitekey(citekey: string, signal?: AbortSignal): Promise<ZoteroItem | null> {
    const query: Record<string, any> = {
      format: "json",
      q: citekey,
      qmode: "everything",
    };
    const rawItems = await this.requestJson<any[]>(`users/${this.config.userId}/items`, query, { signal });
    const match = rawItems.find((r) => {
      const data = r.data ?? r;
      if (typeof data.extra !== "string") return false;
      const lower = data.extra.toLowerCase();
      return lower.includes(`citation-key: ${citekey.toLowerCase()}`) || lower.includes(`citation key: ${citekey.toLowerCase()}`);
    });
    return match ? this.mapItem(match) : null;
  }

  async listCollections(signal?: AbortSignal): Promise<ZoteroCollection[]> {
    const raw = await this.requestJson<any[]>(`users/${this.config.userId}/collections`, { format: "json" }, { signal });
    return raw.map((c) => this.mapCollection(c));
  }

  async listAllCollections(signal?: AbortSignal): Promise<ZoteroCollection[]> {
    const raw = await this.requestJsonPaginated<any>(`users/${this.config.userId}/collections`, undefined, { signal });
    return raw.map((c) => this.mapCollection(c));
  }

  private mapCollection(c: any): ZoteroCollection {
    const data = c.data ?? c;
    const meta = c.meta ?? {};
    return {
      key: data.key,
      name: data.name,
      parentCollection: data.parentCollection && data.parentCollection !== false ? data.parentCollection : null,
      itemCount: typeof meta.numItems === "number" ? meta.numItems : undefined,
    };
  }

  async getCollectionItems(params: GetCollectionItemsParams, signal?: AbortSignal): Promise<ZoteroItemSummary[] | ZoteroItem[]> {
    const query: Record<string, any> = { format: "json" };
    if (params.limit !== undefined) query.limit = params.limit;
    const rawItems = await this.requestJson<any[]>(
      `users/${this.config.userId}/collections/${params.collectionKey}/items`,
      query,
      { signal },
    );
    if (params.full) {
      return rawItems.map((r) => this.mapItem(r));
    }
    return rawItems.map((r) => this.mapItemSummary(r));
  }

  async getAllCollectionItems(collectionKey: string, signal?: AbortSignal): Promise<ZoteroItemSummary[]> {
    const rawItems = await this.requestJsonPaginated<any>(
      `users/${this.config.userId}/collections/${collectionKey}/items`,
      undefined,
      { signal },
    );
    return rawItems.map((r) => this.mapItemSummary(r));
  }

  async listTags(signal?: AbortSignal): Promise<ZoteroTag[]> {
    const raw = await this.requestJson<any[]>(`users/${this.config.userId}/tags`, undefined, { signal });
    return raw.map((t) => {
      const meta = t.meta ?? {};
      return {
        tag: t.tag,
        type: t.type,
        numItems: typeof meta.numItems === "number" ? meta.numItems : undefined,
      };
    });
  }

  async getCitation(params: GetCitationParams, signal?: AbortSignal): Promise<string | any> {
    if (!params.keys.length) return "";
    const itemKey = params.keys.join(",");

    if (params.format === "bibtex") {
      return await this.requestText(`users/${this.config.userId}/items`, { itemKey, format: "bibtex" }, { signal });
    }

    if (params.format === "csljson") {
      return await this.requestJson<any[]>(
        `users/${this.config.userId}/items`,
        { itemKey, format: "csljson" },
        { signal },
      );
    }

    const style = params.style ?? "apa";
    const locale = params.locale ?? "en-US";
    return await this.requestText(
      `users/${this.config.userId}/items`,
      { itemKey, format: "bib", style, locale },
      { signal },
    );
  }

  private async updateItems(items: ZoteroItem[], signal?: AbortSignal): Promise<void> {
    if (!items.length) return;

    for (const item of items) {
      await this.requestText(`users/${this.config.userId}/items/${item.key}`, undefined, {
        method: "PUT",
        body: item.raw,
        signal,
      });
    }
  }

  async addTags(params: ModifyTagsParams, signal?: AbortSignal): Promise<void> {
    if (!params.itemKeys.length || !params.tags.length) return;
    const items = await this.getItemsByKeys(params.itemKeys, signal);
    for (const item of items) {
      const raw = item.raw;
      if (!Array.isArray(raw.tags)) raw.tags = [];
      const existing = new Set<string>(raw.tags.map((t: any) => t.tag).filter(Boolean));
      for (const tag of params.tags) {
        if (!existing.has(tag)) {
          raw.tags.push({ tag });
          existing.add(tag);
        }
      }
    }
    await this.updateItems(items, signal);
  }

  async removeTags(params: ModifyTagsParams, signal?: AbortSignal): Promise<void> {
    if (!params.itemKeys.length || !params.tags.length) return;
    const items = await this.getItemsByKeys(params.itemKeys, signal);
    const toRemove = new Set(params.tags);
    for (const item of items) {
      const raw = item.raw;
      if (!Array.isArray(raw.tags)) continue;
      raw.tags = raw.tags.filter((t: any) => !toRemove.has(t.tag));
    }
    await this.updateItems(items, signal);
  }

  async setTags(params: ModifyTagsParams, signal?: AbortSignal): Promise<void> {
    if (!params.itemKeys.length) return;
    const items = await this.getItemsByKeys(params.itemKeys, signal);
    for (const item of items) {
      item.raw.tags = params.tags.map((tag) => ({ tag }));
    }
    await this.updateItems(items, signal);
  }

  async addToCollections(params: ModifyCollectionsParams, signal?: AbortSignal): Promise<void> {
    if (!params.itemKeys.length || !params.collectionKeys.length) return;
    const items = await this.getItemsByKeys(params.itemKeys, signal);
    const toAdd = new Set(params.collectionKeys);
    for (const item of items) {
      const raw = item.raw;
      if (!Array.isArray(raw.collections)) raw.collections = [];
      const current = new Set<string>(raw.collections);
      for (const c of toAdd) {
        if (!current.has(c)) {
          raw.collections.push(c);
          current.add(c);
        }
      }
    }
    await this.updateItems(items, signal);
  }

  async removeFromCollections(params: ModifyCollectionsParams, signal?: AbortSignal): Promise<void> {
    if (!params.itemKeys.length || !params.collectionKeys.length) return;
    const items = await this.getItemsByKeys(params.itemKeys, signal);
    const toRemove = new Set(params.collectionKeys);
    for (const item of items) {
      const raw = item.raw;
      if (!Array.isArray(raw.collections)) continue;
      raw.collections = raw.collections.filter((c: string) => !toRemove.has(c));
    }
    await this.updateItems(items, signal);
  }

  async createCollection(params: CreateCollectionParams, signal?: AbortSignal): Promise<ZoteroCollection> {
    const body = [
      {
        name: params.name,
        parentCollection: params.parentCollectionKey ?? false,
      },
    ];

    const raw = await this.requestJson<any>(`users/${this.config.userId}/collections`, undefined, {
      method: "POST",
      body,
      signal,
    });

    const successful = raw.successful ?? {};
    const firstKey = Object.keys(successful)[0];
    if (!firstKey) {
      throw new Error("Zotero API returned no successful collection creation result.");
    }

    const entry = successful[firstKey];
    const data = entry.data ?? entry;
    const meta = entry.meta ?? {};
    return {
      key: data.key,
      name: data.name,
      parentCollection: data.parentCollection && data.parentCollection !== false ? data.parentCollection : null,
      itemCount: typeof meta.numItems === "number" ? meta.numItems : undefined,
    };
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "zotero_web",
    label: "Zotero Web",
    description:
      "Manage Zotero via the official Web API: search items, inspect metadata, manage tags and collections, and fetch citations.",
    promptSnippet: "Use Zotero Web API to search and manage items in Zotero.",
    promptGuidelines: [
      "Use this tool to search, inspect, tag, or organize items in Zotero.",
      "Prefer this over the local BibTeX-based zotero tool when the Web API is configured.",
      "Keep write operations (tags/collections) small and reversible.",
    ],
    parameters: Type.Object({
      action: StringEnum([
        "search_items",
        "get_item",
        "get_items",
        "list_collections",
        "list_all_collections",
        "get_collection_items",
        "get_all_collection_items",
        "list_tags",
        "get_citation",
        "add_tags",
        "remove_tags",
        "set_tags",
        "add_to_collections",
        "remove_from_collections",
        "create_collection",
      ] as const),
      query: Type.Optional(Type.String()),
      key: Type.Optional(Type.String()),
      keys: Type.Optional(Type.Array(Type.String())),
      doi: Type.Optional(Type.String()),
      citekey: Type.Optional(Type.String()),
      collectionKey: Type.Optional(Type.String()),
      collectionKeys: Type.Optional(Type.Array(Type.String())),
      itemKeys: Type.Optional(Type.Array(Type.String())),
      tags: Type.Optional(Type.Array(Type.String())),
      name: Type.Optional(Type.String()),
      parentCollectionKey: Type.Optional(Type.String()),
      limit: Type.Optional(Type.Number({ minimum: 1, maximum: 200 })),
      format: Type.Optional(StringEnum(["bibtex", "csljson", "formatted"] as const)),
      style: Type.Optional(Type.String()),
      locale: Type.Optional(Type.String()),
      full: Type.Optional(Type.Boolean()),
      sort: Type.Optional(StringEnum(["title", "dateAdded", "dateModified", "creator", "year"] as const)),
      direction: Type.Optional(StringEnum(["asc", "desc"] as const)),
    }),

    async execute(_toolCallId, params, signal) {
      const apiKey = process.env.ZOTERO_API_KEY;
      const userId = process.env.ZOTERO_USER_ID;

      if (!apiKey || !userId) {
        return {
          content: [
            {
              type: "text" as const,
              text: "ZOTERO_API_KEY and ZOTERO_USER_ID must be set in the environment to use zotero_web.",
            },
          ],
          details: {},
          isError: true,
        };
      }

      const client = new ZoteroWebClient({ apiKey, userId });

      try {
        const action = params.action;

        if (action === "search_items") {
          const items = await client.searchItems(
            {
              query: params.query,
              limit: params.limit ?? 10,
              collectionKey: params.collectionKey,
              sort: params.sort,
              direction: params.direction,
            },
            signal,
          );

          if (!items.length) {
            return {
              content: [{ type: "text" as const, text: "No items found in Zotero." }],
              details: { items },
            };
          }

          const shown = items.slice(0, params.limit ?? 10);
          const lines = shown.map((item) => {
            const year = item.year ?? "n.d.";
            const authors = item.creators?.map((c) => c.family ?? c.lastName ?? c.name ?? "?").join(", ") ||
              "Unknown";
            return `- [${item.key}] ${authors} (${year}). ${item.title}`;
          });
          const header = `Found ${items.length} item(s)${
            items.length > shown.length ? ` (showing first ${shown.length})` : ""
          }:`;

          return {
            content: [{ type: "text" as const, text: [header, ...lines].join("\n") }],
            details: { items },
          };
        }

        if (action === "get_item") {
          const { key, doi, citekey } = params;
          let item: ZoteroItem | null = null;
          if (key) item = await client.getItemByKey(key, signal);
          else if (doi) item = await client.getItemByDOI(doi, signal);
          else if (citekey) item = await client.getItemByCitekey(citekey, signal);
          else {
            throw new Error("get_item requires one of key, doi, or citekey.");
          }

          if (!item) {
            return {
              content: [{ type: "text" as const, text: "Item not found in Zotero." }],
              details: {},
            };
          }

          const year = item.year ?? "n.d.";
          const authors = item.creators?.map((c) => c.family ?? c.lastName ?? c.name ?? "?").join("; ") ||
            "Unknown";
          const summaryLines = [
            `Key: ${item.key}`,
            `Title: ${item.title}`,
            `Authors: ${authors}`,
            `Year: ${year}`,
            `Type: ${item.itemType}`,
            item.tags.length ? `Tags: ${item.tags.join(", ")}` : "Tags: (none)",
            item.collections.length ? `Collections: ${item.collections.join(", ")}` : "Collections: (none)",
          ];

          return {
            content: [{ type: "text" as const, text: summaryLines.join("\n") }],
            details: { item },
          };
        }

        if (action === "get_items") {
          const keys = params.keys ?? params.itemKeys;
          if (!keys?.length) throw new Error("get_items requires keys or itemKeys.");
          const items = await client.getItemsByKeys(keys, signal);
          return {
            content: [
              {
                type: "text" as const,
                text: `Fetched ${items.length} item(s) by key.`,
              },
            ],
            details: { items },
          };
        }

        if (action === "list_collections") {
          const collections = await client.listCollections(signal);
          if (!collections.length) {
            return {
              content: [{ type: "text" as const, text: "No collections in Zotero library." }],
              details: { collections },
            };
          }
          const lines = collections.map((c) => `- [${c.key}] ${c.name}`);
          return {
            content: [
              {
                type: "text" as const,
                text: ["Collections:", ...lines].join("\n"),
              },
            ],
            details: { collections },
          };
        }

        if (action === "list_all_collections") {
          const collections = await client.listAllCollections(signal);
          if (!collections.length) {
            return {
              content: [{ type: "text" as const, text: "No collections in Zotero library." }],
              details: { collections },
            };
          }

          const buildTree = (cols: ZoteroCollection[]): string[] => {
            const byParent = new Map<string | null, ZoteroCollection[]>();
            for (const c of cols) {
              const parent = c.parentCollection ?? null;
              if (!byParent.has(parent)) byParent.set(parent, []);
              byParent.get(parent)!.push(c);
            }
            const lines: string[] = [];
            const walk = (parentKey: string | null, indent: number) => {
              const children = byParent.get(parentKey) ?? [];
              for (const c of children) {
                const prefix = "  ".repeat(indent) + "-";
                const count = c.itemCount !== undefined ? ` (${c.itemCount})` : "";
                lines.push(`${prefix} [${c.key}] ${c.name}${count}`);
                walk(c.key, indent + 1);
              }
            };
            walk(null, 0);
            return lines;
          };

          const lines = buildTree(collections);
          return {
            content: [
              {
                type: "text" as const,
                text: [`All collections (${collections.length}):`, ...lines].join("\n"),
              },
            ],
            details: { collections },
          };
        }

        if (action === "get_collection_items") {
          if (!params.collectionKey) throw new Error("get_collection_items requires collectionKey.");
          const items = await client.getCollectionItems(
            {
              collectionKey: params.collectionKey,
              full: params.full ?? false,
              limit: params.limit ?? 10,
            },
            signal,
          );

          const summaries: ZoteroItemSummary[] = (items as any[]).map((i) =>
            "raw" in i ? (i as ZoteroItem) : (i as ZoteroItemSummary),
          );

          if (!summaries.length) {
            return {
              content: [{ type: "text" as const, text: "Collection has no items." }],
              details: { items },
            };
          }

          const shown = summaries.slice(0, params.limit ?? 10);
          const lines = shown.map((item) => {
            const year = item.year ?? "n.d.";
            return `- [${item.key}] (${year}) ${item.title}`;
          });
          const header = `Collection items: ${summaries.length} item(s)${
            summaries.length > shown.length ? ` (showing first ${shown.length})` : ""
          }:`;

          return {
            content: [{ type: "text" as const, text: [header, ...lines].join("\n") }],
            details: { items },
          };
        }

        if (action === "get_all_collection_items") {
          if (!params.collectionKey) throw new Error("get_all_collection_items requires collectionKey.");
          const items = await client.getAllCollectionItems(params.collectionKey, signal);

          if (!items.length) {
            return {
              content: [{ type: "text" as const, text: "Collection has no items." }],
              details: { items },
            };
          }

          const lines = items.map((item) => {
            const year = item.year ?? "n.d.";
            const authors = item.creators?.map((c) => (c as any).family ?? (c as any).lastName ?? c.name ?? "?").join(", ") || "Unknown";
            return `- [${item.key}] ${authors} (${year}). ${item.title}`;
          });

          return {
            content: [
              {
                type: "text" as const,
                text: [`All items in collection (${items.length}):`, ...lines].join("\n"),
              },
            ],
            details: { items },
          };
        }

        if (action === "list_tags") {
          const tags = await client.listTags(signal);
          if (!tags.length) {
            return {
              content: [{ type: "text" as const, text: "No tags in Zotero library." }],
              details: { tags },
            };
          }
          const lines = tags.map((t) => `- ${t.tag}${t.numItems ? ` (${t.numItems})` : ""}`);
          return {
            content: [
              {
                type: "text" as const,
                text: ["Tags:", ...lines].join("\n"),
              },
            ],
            details: { tags },
          };
        }

        if (action === "get_citation") {
          const keys = params.keys ?? params.itemKeys;
          if (!keys?.length) throw new Error("get_citation requires keys or itemKeys.");
          const format = params.format ?? "bibtex";
          const citation = await client.getCitation({ keys, format, style: params.style, locale: params.locale }, signal);

          // For bibtex / formatted, citation is string; for csljson, it's JSON.
          const text = typeof citation === "string" ? citation : JSON.stringify(citation, null, 2);
          return {
            content: [{ type: "text" as const, text }],
            details: { citation, format },
          };
        }

        if (action === "add_tags") {
          const itemKeys = params.itemKeys ?? params.keys;
          if (!itemKeys?.length || !params.tags?.length) {
            throw new Error("add_tags requires itemKeys/keys and tags.");
          }
          await client.addTags({ itemKeys, tags: params.tags }, signal);
          return {
            content: [
              {
                type: "text" as const,
                text: `Added ${params.tags.length} tag(s) to ${itemKeys.length} item(s).`,
              },
            ],
            details: { itemKeys, tags: params.tags },
          };
        }

        if (action === "remove_tags") {
          const itemKeys = params.itemKeys ?? params.keys;
          if (!itemKeys?.length || !params.tags?.length) {
            throw new Error("remove_tags requires itemKeys/keys and tags.");
          }
          await client.removeTags({ itemKeys, tags: params.tags }, signal);
          return {
            content: [
              {
                type: "text" as const,
                text: `Removed ${params.tags.length} tag(s) from ${itemKeys.length} item(s).`,
              },
            ],
            details: { itemKeys, tags: params.tags },
          };
        }

        if (action === "set_tags") {
          const itemKeys = params.itemKeys ?? params.keys;
          if (!itemKeys?.length) throw new Error("set_tags requires itemKeys/keys.");
          await client.setTags({ itemKeys, tags: params.tags ?? [] }, signal);
          return {
            content: [
              {
                type: "text" as const,
                text: `Set tags for ${itemKeys.length} item(s) to: ${(params.tags ?? []).join(", ") || "(none)"}.`,
              },
            ],
            details: { itemKeys, tags: params.tags ?? [] },
          };
        }

        if (action === "add_to_collections") {
          const itemKeys = params.itemKeys ?? params.keys;
          const collectionKeys = params.collectionKeys ?? (params.collectionKey ? [params.collectionKey] : []);
          if (!itemKeys?.length || !collectionKeys.length) {
            throw new Error("add_to_collections requires itemKeys/keys and collectionKeys/collectionKey.");
          }
          await client.addToCollections({ itemKeys, collectionKeys }, signal);
          return {
            content: [
              {
                type: "text" as const,
                text: `Added ${itemKeys.length} item(s) to ${collectionKeys.length} collection(s).`,
              },
            ],
            details: { itemKeys, collectionKeys },
          };
        }

        if (action === "remove_from_collections") {
          const itemKeys = params.itemKeys ?? params.keys;
          const collectionKeys = params.collectionKeys ?? (params.collectionKey ? [params.collectionKey] : []);
          if (!itemKeys?.length || !collectionKeys.length) {
            throw new Error("remove_from_collections requires itemKeys/keys and collectionKeys/collectionKey.");
          }
          await client.removeFromCollections({ itemKeys, collectionKeys }, signal);
          return {
            content: [
              {
                type: "text" as const,
                text: `Removed ${itemKeys.length} item(s) from ${collectionKeys.length} collection(s).`,
              },
            ],
            details: { itemKeys, collectionKeys },
          };
        }

        if (action === "create_collection") {
          if (!params.name) throw new Error("create_collection requires name.");
          const collection = await client.createCollection(
            { name: params.name, parentCollectionKey: params.parentCollectionKey },
            signal,
          );
          return {
            content: [
              {
                type: "text" as const,
                text: `Created collection [${collection.key}] ${collection.name}.`,
              },
            ],
            details: { collection },
          };
        }

        throw new Error(`Unknown action: ${action}`);
      } catch (e: unknown) {
        const message = e instanceof Error ? e.message : String(e);
        return {
          content: [{ type: "text" as const, text: message }],
          details: {},
          isError: true,
        };
      }
    },

    renderCall(args, theme) {
      let text = theme.fg("toolTitle", theme.bold("zotero_web "));
      text += theme.fg("accent", args.action ?? "");
      if (args.query) text += " " + theme.fg("dim", `"${args.query}"`);
      if (args.key) text += " " + theme.fg("dim", args.key);
      if (args.itemKeys?.length) text += " " + theme.fg("dim", args.itemKeys.join(", "));
      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme) {
      const text = result.content?.[0];
      if (!text || text.type !== "text") return new Text("", 0, 0);

      if (result.isError) return new Text(theme.fg("error", text.text), 0, 0);

      const lines = text.text.split("\n");
      if (!expanded && lines.length > 12) {
        const preview = lines.slice(0, 12).join("\n");
        return new Text(
          preview + "\n" + theme.fg("muted", `... ${lines.length - 12} more line(s)`),
          0,
          0,
        );
      }

      return new Text(text.text, 0, 0);
    },
  });
}
