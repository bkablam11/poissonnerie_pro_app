import express from "express";
import path from "path";
import fs from "fs";
import { createServer as createViteServer } from "vite";

const PORT = 3000;
const DB_FILE = path.join(process.cwd(), "db.json");

// Helper to read database
function readDB() {
  if (!fs.existsSync(DB_FILE)) {
    return {
      products: [],
      sales: [],
      purchases: [],
      losses: [],
      contacts: [],
      ledger: [],
      settings: {
        shopName: "Poissonnerie Pro",
        address: "12 Port de Pêche, Abidjan, Côte d'Ivoire",
        phone: "+225 07 00 00 00 00",
        taxId: "CC-9876543-A",
        currency: "FCFA",
        vatRate: 18,
        lastSync: null,
      },
      updatedAt: Date.now()
    };
  }
  try {
    const data = fs.readFileSync(DB_FILE, "utf-8");
    return JSON.parse(data);
  } catch (err) {
    console.error("Error reading db.json, returning empty template", err);
    return {
      products: [],
      sales: [],
      purchases: [],
      losses: [],
      contacts: [],
      ledger: [],
      settings: {
        shopName: "Poissonnerie Pro",
        address: "12 Port de Pêche, Abidjan, Côte d'Ivoire",
        phone: "+225 07 00 00 00 00",
        taxId: "CC-9876543-A",
        currency: "FCFA",
        vatRate: 18,
        lastSync: null,
      },
      updatedAt: Date.now()
    };
  }
}

// Helper to write database
function writeDB(data: any) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), "utf-8");
  } catch (err) {
    console.error("Error writing db.json", err);
  }
}

async function startServer() {
  const app = express();

  // Parse JSON bodies with limit up to 50MB for synchronization bundles
  app.use(express.json({ limit: "50mb" }));
  app.use(express.urlencoded({ extended: true, limit: "50mb" }));

  // --- API ROUTES ---

  // Health check
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok", time: new Date().toISOString() });
  });

  // Pull server data
  app.get("/api/sync", (req, res) => {
    const db = readDB();
    res.json({ success: true, data: db });
  });

  // Push server sync & merge
  app.post("/api/sync", (req, res) => {
    const incoming = req.body;
    const current = readDB();

    // Standard local-wins or server-wins merge logic
    // We'll merge by replacing or appending items based on ID matches, updating timestamps
    const mergeList = (serverList: any[], clientList: any[]) => {
      const mergedMap = new Map();
      serverList.forEach((item) => mergedMap.set(item.id, item));
      clientList.forEach((item) => {
        // If the item doesn't exist or is newer, overwrite
        const existing = mergedMap.get(item.id);
        if (!existing || (item.updatedAt && (!existing.updatedAt || item.updatedAt > existing.updatedAt))) {
          mergedMap.set(item.id, { ...item, isSynced: true });
        }
      });
      return Array.from(mergedMap.values());
    };

    const newDB = {
      products: mergeList(current.products || [], incoming.products || []),
      sales: mergeList(current.sales || [], incoming.sales || []),
      purchases: mergeList(current.purchases || [], incoming.purchases || []),
      losses: mergeList(current.losses || [], incoming.losses || []),
      contacts: mergeList(current.contacts || [], incoming.contacts || []),
      ledger: mergeList(current.ledger || [], incoming.ledger || []),
      settings: incoming.settings ? { ...current.settings, ...incoming.settings, lastSync: Date.now() } : current.settings,
      updatedAt: Date.now(),
    };

    writeDB(newDB);

    res.json({
      success: true,
      message: "Synchronisation réussie",
      data: newDB,
    });
  });

  // Clear remote db (useful for reset buttons)
  app.post("/api/sync/reset", (req, res) => {
    if (fs.existsSync(DB_FILE)) {
      fs.unlinkSync(DB_FILE);
    }
    res.json({ success: true, message: "Base de données distante réinitialisée" });
  });

  // --- VITE MIDDLEWARE SETUP ---
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[Poissonnerie Pro] Server running on http://localhost:${PORT} (Node: ${process.version})`);
  });
}

startServer().catch((err) => {
  console.error("Failed to start server:", err);
});
