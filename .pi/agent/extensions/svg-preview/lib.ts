import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

export const MAX_SVG_BYTES = 2 * 1024 * 1024;
export const MAX_RASTER_DIMENSION = 1600;

export type SvgFit =
	| { mode: "original" }
	| { mode: "width"; value: number }
	| { mode: "height"; value: number };

export const selectSvgFit = (
	width: number,
	height: number,
	maxDimension = MAX_RASTER_DIMENSION,
): SvgFit => {
	if (!Number.isFinite(width) || width <= 0 || !Number.isFinite(height) || height <= 0) {
		throw new Error("SVG has invalid intrinsic dimensions");
	}
	if (!Number.isFinite(maxDimension) || maxDimension <= 0) {
		throw new Error("Raster size limit must be positive");
	}
	if (width <= maxDimension && height <= maxDimension) return { mode: "original" };
	return width >= height
		? { mode: "width", value: maxDimension }
		: { mode: "height", value: maxDimension };
};

export const validateSvgSize = (size: number): void => {
	if (size > MAX_SVG_BYTES) {
		throw new Error(`SVG exceeds the ${MAX_SVG_BYTES / 1024 / 1024} MB limit`);
	}
};

const unwrapQuotes = (value: string): string => {
	if (value.length < 2) return value;
	const first = value[0];
	const last = value[value.length - 1];
	return (first === '"' && last === '"') || (first === "'" && last === "'")
		? value.slice(1, -1)
		: value;
};

export const resolveSvgPath = (argument: string, cwd: string, home = homedir()): string => {
	let value = unwrapQuotes(argument.trim());
	if (value.startsWith("@")) value = unwrapQuotes(value.slice(1).trim());
	if (!value) throw new Error("Usage: /svgp <path>");

	if (value === "~") return home;
	if (value.startsWith("~/")) return join(home, value.slice(2));
	return isAbsolute(value) ? resolve(value) : resolve(cwd, value);
};

export const validateSvgBuffer = (buffer: Buffer): void => {
	validateSvgSize(buffer.byteLength);

	const source = buffer.toString("utf8").replace(/^\uFEFF?\s*/, "");
	const hasSvgRoot = /^(?:(?:<\?xml[\s\S]*?\?>|<!--[\s\S]*?-->|<!doctype[\s\S]*?>)\s*)*<svg(?:\s|\/?>)/i.test(source);
	if (!hasSvgRoot) throw new Error("File does not contain an SVG root element");
};

export const formatUpdatedTime = (timestamp: number): string =>
	new Date(timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
