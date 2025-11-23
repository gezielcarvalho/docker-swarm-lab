const express = require("express");
const morgan = require("morgan");
const cors = require("cors");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || "development";
const VERSION = process.env.APP_VERSION || "1.0.0";

// Middleware
app.use(cors());
app.use(morgan("combined"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// In-memory data store (for demo purposes)
let items = [
  {
    id: 1,
    name: "Item 1",
    description: "First item",
    createdAt: new Date().toISOString(),
  },
  {
    id: 2,
    name: "Item 2",
    description: "Second item",
    createdAt: new Date().toISOString(),
  },
  {
    id: 3,
    name: "Item 3",
    description: "Third item",
    createdAt: new Date().toISOString(),
  },
];

// Routes

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: NODE_ENV,
    version: VERSION,
  });
});

// Info endpoint
app.get("/api/info", (req, res) => {
  res.json({
    application: "Docker Swarm Lab API",
    version: VERSION,
    environment: NODE_ENV,
    nodeVersion: process.version,
    platform: process.platform,
    hostname: require("os").hostname(),
  });
});

// Get all items
app.get("/api/items", (req, res) => {
  res.json({
    success: true,
    count: items.length,
    data: items,
  });
});

// Get single item
app.get("/api/items/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const item = items.find((i) => i.id === id);

  if (!item) {
    return res.status(404).json({
      success: false,
      error: "Item not found",
    });
  }

  res.json({
    success: true,
    data: item,
  });
});

// Create item
app.post("/api/items", (req, res) => {
  const { name, description } = req.body;

  if (!name) {
    return res.status(400).json({
      success: false,
      error: "Name is required",
    });
  }

  const newItem = {
    id: items.length > 0 ? Math.max(...items.map((i) => i.id)) + 1 : 1,
    name,
    description: description || "",
    createdAt: new Date().toISOString(),
  };

  items.push(newItem);

  res.status(201).json({
    success: true,
    data: newItem,
  });
});

// Update item
app.put("/api/items/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex((i) => i.id === id);

  if (itemIndex === -1) {
    return res.status(404).json({
      success: false,
      error: "Item not found",
    });
  }

  const { name, description } = req.body;

  if (name) items[itemIndex].name = name;
  if (description !== undefined) items[itemIndex].description = description;
  items[itemIndex].updatedAt = new Date().toISOString();

  res.json({
    success: true,
    data: items[itemIndex],
  });
});

// Delete item
app.delete("/api/items/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex((i) => i.id === id);

  if (itemIndex === -1) {
    return res.status(404).json({
      success: false,
      error: "Item not found",
    });
  }

  const deletedItem = items.splice(itemIndex, 1)[0];

  res.json({
    success: true,
    data: deletedItem,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: "Route not found",
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: "Internal server error",
  });
});

// Start server
const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Docker Swarm Lab API Server                             ║
║                                                           ║
║   Environment: ${NODE_ENV.padEnd(43)}║
║   Version:     ${VERSION.padEnd(43)}║
║   Port:        ${PORT.toString().padEnd(43)}║
║   Node:        ${process.version.padEnd(43)}║
║                                                           ║
║   Endpoints:                                              ║
║   - GET  /health                                          ║
║   - GET  /api/info                                        ║
║   - GET  /api/items                                       ║
║   - GET  /api/items/:id                                   ║
║   - POST /api/items                                       ║
║   - PUT  /api/items/:id                                   ║
║   - DELETE /api/items/:id                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM signal received: closing HTTP server");
  server.close(() => {
    console.log("HTTP server closed");
    process.exit(0);
  });
});

module.exports = app;
