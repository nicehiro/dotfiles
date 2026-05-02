import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { withFileMutationQueue } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Image, Text } from "@mariozechner/pi-tui";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, extname, isAbsolute, resolve } from "node:path";
import { Type } from "@sinclair/typebox";

const DEFAULT_BASE_URL = "https://api.openai.com";
const DEFAULT_MODEL = "gpt-image-2";
const FORMAT_EXTENSIONS = {
	png: "png",
	jpeg: "jpg",
	webp: "webp",
} as const;
const MIME_TYPES = {
	png: "image/png",
	jpeg: "image/jpeg",
	webp: "image/webp",
} as const;

type OutputFormat = keyof typeof FORMAT_EXTENSIONS;

interface ImageGenerateDetails {
	model: string;
	path: string;
	count: number;
	size: string;
	quality: string;
	output_format: OutputFormat;
	background: string;
	files: string[];
	images: Array<{ path: string; mimeType: string; data: string }>;
	usage?: unknown;
}

function getBaseUrl(): string {
	return (process.env.PI_GPT_IMAGE_BASE_URL || process.env.OPENAI_BASE_URL || DEFAULT_BASE_URL).replace(/\/$/, "");
}

function getApiKey(): string {
	const key = process.env.PI_GPT_IMAGE_API_KEY || process.env.OPENAI_API_KEY;
	if (!key) throw new Error("Set OPENAI_API_KEY or PI_GPT_IMAGE_API_KEY to use gpt_image_generate");
	return key;
}

function defaultOutputPath(format: OutputFormat): string {
	const stamp = new Date().toISOString().replace(/[:.]/g, "-");
	return `gpt-image-${stamp}.${FORMAT_EXTENSIONS[format]}`;
}

function normalizeOutputPath(cwd: string, outputPath: string, format: OutputFormat): string {
	const stripped = outputPath.replace(/^@/, "");
	const path = isAbsolute(stripped) ? stripped : resolve(cwd, stripped);
	return extname(path) ? path : `${path}.${FORMAT_EXTENSIONS[format]}`;
}

function indexedPath(path: string, index: number): string {
	if (index === 0) return path;
	const ext = extname(path);
	return ext ? `${path.slice(0, -ext.length)}-${index + 1}${ext}` : `${path}-${index + 1}`;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "gpt_image_generate",
		label: "GPT Image Generate",
		description:
			"Generate images with OpenAI-compatible GPT Image models, defaulting to gpt-image-2. Saves PNG, JPEG, or WebP files to disk.",
		promptSnippet:
			"Generate images with GPT Image models. Supports png/jpeg/webp output, size, quality, background, compression, moderation, and n images. Saves files to disk.",
		promptGuidelines: [
			"Use gpt_image_generate when the user explicitly asks to create or generate raster images. Do not use it for SVG; GPT Image models only return png, jpeg, or webp.",
			"Before calling gpt_image_generate, mention that image generation may consume paid API credits unless the user has already approved generation in the current task.",
		],
		parameters: Type.Object({
			prompt: Type.String({ description: "Text description of the desired image" }),
			outputPath: Type.Optional(
				Type.String({ description: "Where to save the image. Relative paths resolve from the current working directory." })
			),
			model: Type.Optional(Type.String({ description: "Image model to use (default: gpt-image-2)", default: DEFAULT_MODEL })),
			size: Type.Optional(
				StringEnum(["auto", "1024x1024", "1536x1024", "1024x1536"] as const, {
					description: "Generated image size (default: auto)",
					default: "auto",
				})
			),
			quality: Type.Optional(
				StringEnum(["auto", "low", "medium", "high"] as const, {
					description: "Image quality (default: auto)",
					default: "auto",
				})
			),
			output_format: Type.Optional(
				StringEnum(["png", "jpeg", "webp"] as const, {
					description: "Output format (default: png). SVG is not supported.",
					default: "png",
				})
			),
			background: Type.Optional(
				StringEnum(["auto", "transparent", "opaque"] as const, {
					description: "Background handling. Transparent requires png or webp.",
					default: "auto",
				})
			),
			output_compression: Type.Optional(
				Type.Number({ description: "Compression level 0-100 for jpeg/webp outputs" })
			),
			moderation: Type.Optional(
				StringEnum(["auto", "low"] as const, { description: "Moderation level (default: auto)", default: "auto" })
			),
			n: Type.Optional(Type.Number({ description: "Number of images to generate, 1-10 (default: 1)", default: 1 })),
		}),

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const model = params.model ?? DEFAULT_MODEL;
			const output_format = (params.output_format ?? "png") as OutputFormat;
			const background = params.background ?? "auto";
			const size = params.size ?? "auto";
			const quality = params.quality ?? "auto";
			const moderation = params.moderation ?? "auto";
			const n = params.n ?? 1;

			if (!Number.isInteger(n) || n < 1 || n > 10) throw new Error("n must be an integer between 1 and 10");
			if (params.output_compression !== undefined) {
				if (params.output_compression < 0 || params.output_compression > 100) {
					throw new Error("output_compression must be between 0 and 100");
				}
				if (output_format === "png") throw new Error("output_compression is only supported for jpeg or webp");
			}
			if (background === "transparent" && output_format === "jpeg") {
				throw new Error("transparent background requires png or webp output_format");
			}

			const basePath = normalizeOutputPath(ctx.cwd, params.outputPath ?? defaultOutputPath(output_format), output_format);
			const files = Array.from({ length: n }, (_, i) => indexedPath(basePath, i));

			return withFileMutationQueue(basePath, async () => {
				onUpdate?.({
					content: [{ type: "text", text: `Generating ${n} image${n === 1 ? "" : "s"} with ${model}...` }],
					details: { model, path: basePath, count: n },
				});

				const body: Record<string, unknown> = {
					model,
					prompt: params.prompt,
					n,
					size,
					quality,
					output_format,
					background,
					moderation,
				};
				if (params.output_compression !== undefined) body.output_compression = params.output_compression;

				const resp = await fetch(`${getBaseUrl()}/v1/images/generations`, {
					method: "POST",
					signal,
					headers: {
						Authorization: `Bearer ${getApiKey()}`,
						"Content-Type": "application/json",
					},
					body: JSON.stringify(body),
				});

				const text = await resp.text();
				let json: any;
				try {
					json = JSON.parse(text);
				} catch {
					throw new Error(`Image API returned non-JSON response (${resp.status}): ${text.slice(0, 500)}`);
				}
				if (!resp.ok) {
					const message = json?.error?.message ?? text.slice(0, 500);
					throw new Error(`Image API error ${resp.status}: ${message}`);
				}
				if (!Array.isArray(json.data) || json.data.length === 0) throw new Error("Image API returned no images");

				const images: ImageGenerateDetails["images"] = [];
				for (let i = 0; i < json.data.length; i++) {
					const b64 = json.data[i]?.b64_json;
					if (typeof b64 !== "string" || b64.length === 0) throw new Error(`Image ${i + 1} missing b64_json`);
					const file = files[i] ?? indexedPath(basePath, i);
					await mkdir(dirname(file), { recursive: true });
					await writeFile(file, Buffer.from(b64, "base64"));
					images.push({ path: file, mimeType: MIME_TYPES[output_format], data: b64 });
				}

				const details: ImageGenerateDetails = {
					model,
					path: basePath,
					count: images.length,
					size,
					quality,
					output_format,
					background,
					files: images.map((image) => image.path),
					images,
					usage: json.usage,
				};

				return {
					content: [
						{ type: "text", text: `Generated ${images.length} image${images.length === 1 ? "" : "s"}:\n${details.files.join("\n")}` },
						...images.map((image) => ({ type: "image", data: image.data, mimeType: image.mimeType })),
					],
					details,
				};
			});
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("gpt-image "));
			text += theme.fg("accent", args.model ?? DEFAULT_MODEL);
			text += theme.fg("dim", ` ${args.output_format ?? "png"} ${args.size ?? "auto"}`);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as ImageGenerateDetails | undefined;
			if (!details) return new Text(theme.fg("dim", "No image details"), 0, 0);

			if (expanded && details.images[0]) {
				return new Image(details.images[0].data, details.images[0].mimeType, theme, {
					maxWidthCells: 80,
					maxHeightCells: 32,
				});
			}

			let text = theme.fg("success", `Generated ${details.count} image${details.count === 1 ? "" : "s"}`);
			text += theme.fg("dim", ` with ${details.model}`);
			for (const file of details.files) text += `\n${theme.fg("accent", file)}`;
			return new Text(text, 0, 0);
		},
	});
}
