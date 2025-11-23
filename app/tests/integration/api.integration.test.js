const request = require("supertest");
const app = require("../../src/index");

describe("API Integration Tests", () => {
  describe("Complete CRUD Workflow", () => {
    let createdItemId;

    it("should complete full item lifecycle", async () => {
      // 1. Get initial items count
      const initialRes = await request(app).get("/api/items");
      expect(initialRes.statusCode).toBe(200);
      const initialCount = initialRes.body.count;

      // 2. Create new item
      const createRes = await request(app).post("/api/items").send({
        name: "Integration Test Item",
        description: "Created during integration test",
      });

      expect(createRes.statusCode).toBe(201);
      expect(createRes.body.success).toBe(true);
      createdItemId = createRes.body.data.id;
      expect(createdItemId).toBeDefined();

      // 3. Verify item exists
      const getRes = await request(app).get(`/api/items/${createdItemId}`);
      expect(getRes.statusCode).toBe(200);
      expect(getRes.body.data.name).toBe("Integration Test Item");

      // 4. Update item
      const updateRes = await request(app)
        .put(`/api/items/${createdItemId}`)
        .send({
          name: "Updated Integration Test Item",
          description: "Modified description",
        });

      expect(updateRes.statusCode).toBe(200);
      expect(updateRes.body.data.name).toBe("Updated Integration Test Item");
      expect(updateRes.body.data.updatedAt).toBeDefined();

      // 5. Verify update
      const verifyRes = await request(app).get(`/api/items/${createdItemId}`);
      expect(verifyRes.body.data.name).toBe("Updated Integration Test Item");

      // 6. Delete item
      const deleteRes = await request(app).delete(
        `/api/items/${createdItemId}`
      );
      expect(deleteRes.statusCode).toBe(200);
      expect(deleteRes.body.success).toBe(true);

      // 7. Verify deletion
      const deletedRes = await request(app).get(`/api/items/${createdItemId}`);
      expect(deletedRes.statusCode).toBe(404);

      // 8. Verify count is back to initial
      const finalRes = await request(app).get("/api/items");
      expect(finalRes.body.count).toBe(initialCount);
    });
  });

  describe("Health and Info Endpoints", () => {
    it("should have consistent environment info", async () => {
      const healthRes = await request(app).get("/health");
      const infoRes = await request(app).get("/api/info");

      expect(healthRes.statusCode).toBe(200);
      expect(infoRes.statusCode).toBe(200);

      // Both should report same environment
      expect(healthRes.body.environment).toBe(infoRes.body.environment);

      // Both should report same version
      expect(healthRes.body.version).toBe(infoRes.body.version);
    });

    it("should return healthy status consistently", async () => {
      // Make multiple requests
      const requests = Array(5)
        .fill(null)
        .map(() => request(app).get("/health"));

      const responses = await Promise.all(requests);

      responses.forEach((res) => {
        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe("healthy");
      });
    });
  });

  describe("Concurrent Operations", () => {
    it("should handle concurrent item creation", async () => {
      const items = [
        { name: "Concurrent Item 1", description: "First" },
        { name: "Concurrent Item 2", description: "Second" },
        { name: "Concurrent Item 3", description: "Third" },
      ];

      const createPromises = items.map((item) =>
        request(app).post("/api/items").send(item)
      );

      const responses = await Promise.all(createPromises);

      // All should succeed
      responses.forEach((res) => {
        expect(res.statusCode).toBe(201);
        expect(res.body.success).toBe(true);
      });

      // All should have unique IDs
      const ids = responses.map((res) => res.body.data.id);
      const uniqueIds = new Set(ids);
      expect(uniqueIds.size).toBe(ids.length);
    });

    it("should handle concurrent reads", async () => {
      const readPromises = Array(10)
        .fill(null)
        .map(() => request(app).get("/api/items"));

      const responses = await Promise.all(readPromises);

      // All should succeed with same data
      const firstCount = responses[0].body.count;
      responses.forEach((res) => {
        expect(res.statusCode).toBe(200);
        expect(res.body.count).toBe(firstCount);
      });
    });
  });

  describe("Error Handling", () => {
    it("should handle invalid JSON gracefully", async () => {
      const res = await request(app)
        .post("/api/items")
        .set("Content-Type", "application/json")
        .send("{ invalid json }");

      expect(res.statusCode).toBe(400);
    });

    it("should handle missing content-type", async () => {
      const res = await request(app).post("/api/items").send("name=Test");

      // Should still work with URL-encoded data
      expect([200, 201, 400]).toContain(res.statusCode);
    });
  });

  describe("Performance", () => {
    it("should respond to health check quickly", async () => {
      const start = Date.now();
      const res = await request(app).get("/health");
      const duration = Date.now() - start;

      expect(res.statusCode).toBe(200);
      expect(duration).toBeLessThan(100); // Should respond in less than 100ms
    });

    it("should handle bulk reads efficiently", async () => {
      const start = Date.now();

      const promises = Array(20)
        .fill(null)
        .map(() => request(app).get("/api/items"));

      await Promise.all(promises);

      const duration = Date.now() - start;
      expect(duration).toBeLessThan(2000); // 20 requests in less than 2s
    });
  });
});
