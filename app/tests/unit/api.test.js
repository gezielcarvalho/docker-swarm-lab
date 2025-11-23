const request = require("supertest");
const app = require("../../src/index");

describe("API Endpoints - Unit Tests", () => {
  describe("GET /health", () => {
    it("should return health status", async () => {
      const res = await request(app).get("/health");

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("status", "healthy");
      expect(res.body).toHaveProperty("timestamp");
      expect(res.body).toHaveProperty("uptime");
      expect(res.body).toHaveProperty("environment");
      expect(res.body).toHaveProperty("version");
    });
  });

  describe("GET /api/info", () => {
    it("should return application info", async () => {
      const res = await request(app).get("/api/info");

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("application");
      expect(res.body).toHaveProperty("version");
      expect(res.body).toHaveProperty("environment");
      expect(res.body).toHaveProperty("nodeVersion");
      expect(res.body).toHaveProperty("platform");
      expect(res.body).toHaveProperty("hostname");
    });
  });

  describe("GET /api/items", () => {
    it("should return all items", async () => {
      const res = await request(app).get("/api/items");

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("success", true);
      expect(res.body).toHaveProperty("count");
      expect(res.body).toHaveProperty("data");
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
    });
  });

  describe("GET /api/items/:id", () => {
    it("should return a single item", async () => {
      const res = await request(app).get("/api/items/1");

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("success", true);
      expect(res.body.data).toHaveProperty("id", 1);
      expect(res.body.data).toHaveProperty("name");
      expect(res.body.data).toHaveProperty("description");
    });

    it("should return 404 for non-existent item", async () => {
      const res = await request(app).get("/api/items/9999");

      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty("success", false);
      expect(res.body).toHaveProperty("error", "Item not found");
    });
  });

  describe("POST /api/items", () => {
    it("should create a new item", async () => {
      const newItem = {
        name: "Test Item",
        description: "Test Description",
      };

      const res = await request(app).post("/api/items").send(newItem);

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty("success", true);
      expect(res.body.data).toHaveProperty("id");
      expect(res.body.data).toHaveProperty("name", newItem.name);
      expect(res.body.data).toHaveProperty("description", newItem.description);
      expect(res.body.data).toHaveProperty("createdAt");
    });

    it("should return 400 when name is missing", async () => {
      const res = await request(app)
        .post("/api/items")
        .send({ description: "No name" });

      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty("success", false);
      expect(res.body).toHaveProperty("error", "Name is required");
    });
  });

  describe("PUT /api/items/:id", () => {
    it("should update an existing item", async () => {
      const updates = {
        name: "Updated Item",
        description: "Updated Description",
      };

      const res = await request(app).put("/api/items/1").send(updates);

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty("success", true);
      expect(res.body.data).toHaveProperty("name", updates.name);
      expect(res.body.data).toHaveProperty("description", updates.description);
      expect(res.body.data).toHaveProperty("updatedAt");
    });

    it("should return 404 for non-existent item", async () => {
      const res = await request(app)
        .put("/api/items/9999")
        .send({ name: "Updated" });

      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty("success", false);
    });
  });

  describe("DELETE /api/items/:id", () => {
    it("should delete an item", async () => {
      // First create an item to delete
      const createRes = await request(app)
        .post("/api/items")
        .send({ name: "To Delete", description: "Will be deleted" });

      const itemId = createRes.body.data.id;

      const deleteRes = await request(app).delete(`/api/items/${itemId}`);

      expect(deleteRes.statusCode).toBe(200);
      expect(deleteRes.body).toHaveProperty("success", true);
      expect(deleteRes.body.data).toHaveProperty("id", itemId);
    });

    it("should return 404 for non-existent item", async () => {
      const res = await request(app).delete("/api/items/9999");

      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty("success", false);
    });
  });

  describe("404 Handler", () => {
    it("should return 404 for unknown routes", async () => {
      const res = await request(app).get("/api/unknown");

      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty("success", false);
      expect(res.body).toHaveProperty("error", "Route not found");
    });
  });
});
