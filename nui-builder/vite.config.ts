import { appendFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
import type { Plugin } from "vite";
import { defineConfig } from "vite";

function nuiDebugLogsPlugin(): Plugin {
  const logsDir = resolve(__dirname, "debug-logs");

  return {
    name: "nui-debug-logs",
    configureServer(server) {
      mkdirSync(logsDir, { recursive: true });

      server.middlewares.use("/__nui_debug_log__", (req, res, next) => {
        if (req.method !== "POST") {
          next();
          return;
        }

        let rawBody = "";
        req.on("data", (chunk) => {
          rawBody += String(chunk);
        });
        req.on("end", () => {
          try {
            const parsed = JSON.parse(rawBody || "{}") as { entries?: unknown };
            const rawEntries = Array.isArray(parsed.entries) ? parsed.entries : [];
            const now = new Date();
            const stamp = now.toISOString();
            const dayStamp = stamp.slice(0, 10);
            const fileName = `nui-builder-${dayStamp}.ndjson`;
            const filePath = resolve(logsDir, fileName);
            const lines = rawEntries
              .map((entry) => JSON.stringify({ ...entry, serverReceivedAt: stamp }))
              .join("\n");
            if (lines) {
              appendFileSync(filePath, `${lines}\n`, "utf8");
            }
            res.statusCode = 200;
            res.setHeader("Content-Type", "application/json");
            res.end(JSON.stringify({ ok: true, count: rawEntries.length, file: `debug-logs/${fileName}` }));
          } catch (error) {
            res.statusCode = 400;
            res.setHeader("Content-Type", "application/json");
            res.end(
              JSON.stringify({
                ok: false,
                error: error instanceof Error ? error.message : "Invalid debug payload.",
              }),
            );
          }
        });
      });
    },
  };
}

function resolveBasePath(): string {
  const fromEnv = process.env.VITE_BASE_PATH?.trim();
  if (fromEnv) {
    if (fromEnv === "/") return "/";
    return `/${fromEnv.replace(/^\/+|\/+$/g, "")}/`;
  }

  if (process.env.GITHUB_ACTIONS === "true") {
    const repoName = process.env.GITHUB_REPOSITORY?.split("/")[1]?.trim();
    if (repoName) {
      return `/${repoName}/`;
    }
  }

  return "/";
}

export default defineConfig({
  base: resolveBasePath(),
  plugins: [nuiDebugLogsPlugin()],
  server: {
    port: 5174,
    strictPort: false,
  },
});
