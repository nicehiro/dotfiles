import { ProxyAgent } from "undici";

const proxyUrl = process.env.HTTPS_PROXY || process.env.HTTP_PROXY || process.env.ALL_PROXY;
const fetchOptions = proxyUrl ? { dispatcher: new ProxyAgent(proxyUrl) } : {};

export function proxyFetch(url, opts = {}) {
	return fetch(url, { ...fetchOptions, ...opts });
}
