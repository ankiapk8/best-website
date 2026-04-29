import express, { type Express, type Request, type Response, type NextFunction } from "express";
import cors from "cors";
import pinoHttp from "pino-http";
import path from "node:path";
import router from "./routes";
import { logger } from "./lib/logger";

const app: Express = express();

app.use(
  pinoHttp({
    logger,
    serializers: {
      req(req) {
        return {
          id: req.id,
          method: req.method,
          url: req.url?.split("?")[0],
        };
      },
      res(res) {
        return {
          statusCode: res.statusCode,
        };
      },
    },
  }),
);
app.use(cors());
app.use(express.json({ limit: "200mb" }));
app.use(express.urlencoded({ extended: true, limit: "200mb" }));

app.use("/api", router);

// Serve static files from the frontend build directory
const staticPath = path.resolve(__dirname, "../../anki-generator/dist/public");
app.use(express.static(staticPath));

// Handle client-side routing by serving index.html for non-API routes
app.get("*", (req, res) => {
  res.sendFile(path.join(staticPath, "index.html"));
});

app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
  const message = err instanceof Error ? err.message : "Internal server error";
  logger.error({ err, url: req.url, method: req.method }, "Unhandled error");
  if (!res.headersSent) {
    res.status(500).json({ error: message });
  }
});

export default app;

