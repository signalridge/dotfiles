import { generateSummary, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

import createEarlyCompaction from "./core.ts";

export * from "./core.ts";

export default function (pi: ExtensionAPI) {
  createEarlyCompaction(pi, { generateSummary });
}
