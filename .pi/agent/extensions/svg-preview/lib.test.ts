import assert from "node:assert/strict";
import test from "node:test";
import {
	MAX_SVG_BYTES,
	resolveSvgPath,
	selectSvgFit,
	validateSvgBuffer,
	validateSvgSize,
} from "./lib.ts";

test("resolveSvgPath handles relative, absolute, home, quoted, and @ paths", () => {
	assert.equal(resolveSvgPath("icon.svg", "/work", "/home/me"), "/work/icon.svg");
	assert.equal(resolveSvgPath("/tmp/icon.svg", "/work", "/home/me"), "/tmp/icon.svg");
	assert.equal(resolveSvgPath("~/icon.svg", "/work", "/home/me"), "/home/me/icon.svg");
	assert.equal(resolveSvgPath("'my icon.svg'", "/work", "/home/me"), "/work/my icon.svg");
	assert.equal(resolveSvgPath('@"my icon.svg"', "/work", "/home/me"), "/work/my icon.svg");
});

test("resolveSvgPath rejects an empty argument", () => {
	assert.throws(() => resolveSvgPath("  ", "/work"), /Usage/);
});

test("validateSvgBuffer accepts common SVG prefixes", () => {
	assert.doesNotThrow(() => validateSvgBuffer(Buffer.from('<svg viewBox="0 0 10 10"></svg>')));
	assert.doesNotThrow(() => validateSvgBuffer(Buffer.from('<svg viewBox="0 0 10 10"/>')));
	assert.doesNotThrow(() => validateSvgBuffer(Buffer.from('<?xml version="1.0"?>\n<!-- icon -->\n<svg></svg>')));
	assert.doesNotThrow(() => validateSvgBuffer(Buffer.from('<!DOCTYPE svg PUBLIC "x" "y">\n<svg></svg>')));
});

test("validateSvgBuffer rejects non-SVG content", () => {
	assert.throws(() => validateSvgBuffer(Buffer.from("<html><svg></svg></html>")), /SVG root/);
});

test("validateSvgBuffer enforces the size limit", () => {
	assert.throws(() => validateSvgBuffer(Buffer.alloc(MAX_SVG_BYTES + 1)), /2 MB/);
	assert.throws(() => validateSvgSize(MAX_SVG_BYTES + 1), /2 MB/);
});

test("selectSvgFit preserves small SVGs and limits the longest dimension", () => {
	assert.deepEqual(selectSvgFit(800, 600), { mode: "original" });
	assert.deepEqual(selectSvgFit(3200, 1200), { mode: "width", value: 1600 });
	assert.deepEqual(selectSvgFit(400, 5000), { mode: "height", value: 1600 });
});

test("selectSvgFit rejects invalid dimensions", () => {
	assert.throws(() => selectSvgFit(0, 100), /invalid intrinsic dimensions/);
	assert.throws(() => selectSvgFit(100, Number.POSITIVE_INFINITY), /invalid intrinsic dimensions/);
	assert.throws(() => selectSvgFit(100, 100, 0), /size limit must be positive/);
});
