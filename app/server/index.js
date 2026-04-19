// ──────────────────────────────────────────────────────────────
// Arabic Course — Express server
// Serves static files + API routes + lesson access control
// ──────────────────────────────────────────────────────────────

// Load .env file locally. In production (Railway) env vars are injected
// by the platform, so this is a no-op if .env doesn't exist.
import "dotenv/config";

import express from "express";
import cookieParser from "cookie-parser";
import rateLimit from "express-rate-limit";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

import meRouter from "./api/me.js";
import lessonsRouter from "./api/lessons.js";
import { lessonAccessMiddleware } from "./middleware/lessonAccess.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const APP_ROOT = join(__dirname, "..");                  // app/

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || "development";

const app = express();

// ── Core middleware ────────────────────────────────────────────
app.use(cookieParser());
app.use(express.json({ limit: "100kb" }));

// Trust Railway's proxy (needed for rate limiter + secure cookies)
app.set("trust proxy", 1);

// Global rate limit (safety net against abuse)
app.use("/api", rateLimit({
  windowMs: 60 * 1000,      // 1 minute
  max: 60,                  // 60 req/min per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "too_many_requests" },
}));

// ── Health check (for Railway + smoke tests) ──────────────────
app.get("/api/health", (req, res) => {
  res.json({
    ok: true,
    env: NODE_ENV,
    supabase_configured: !!(process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY),
    admin_configured: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
    timestamp: new Date().toISOString(),
  });
});

// ── API routes ────────────────────────────────────────────────
app.use("/api/me", meRouter);
app.use("/api/lessons", lessonsRouter);

// ── Lesson access middleware ──────────────────────────────────
// Runs BEFORE static so legacy /lessons/lesson_NN.html requests are
// auth-checked. Free lessons (1-2) and non-lesson files pass through.
// Paid lessons without access → redirect to /pricing.html.
// Long-term these static HTML files will be deleted entirely once the
// dynamic /lesson.html?id=N shell is in place.
app.use(lessonAccessMiddleware);

// ── Static assets ─────────────────────────────────────────────
// Serve everything in app/ as static.
app.use(express.static(APP_ROOT, {
  extensions: ["html"],
  index: "index.html",
  setHeaders(res, path) {
    // Cache HTML less aggressively, let browsers recheck
    if (path.endsWith(".html")) {
      res.setHeader("Cache-Control", "no-cache, must-revalidate");
    }
  },
}));

// ── SPA fallback / 404 ────────────────────────────────────────
app.use((req, res) => {
  res.status(404).send("404 — Not Found");
});

// ── Error handler ─────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error("[server error]", err);
  res.status(500).json({ error: "internal_server_error" });
});

// ── Boot ──────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[arabic-course] listening on http://localhost:${PORT}`);
  console.log(`[arabic-course] env: ${NODE_ENV}`);
  console.log(`[arabic-course] app root: ${APP_ROOT}`);
});
