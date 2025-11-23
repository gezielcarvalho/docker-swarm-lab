# Node.js Application

Simple Express.js REST API for Docker Swarm CI/CD simulation.

## Features

- RESTful API endpoints
- Health check endpoint
- Unit tests (Jest)
- Integration tests (Supertest)
- Docker containerization
- Environment-based configuration

## API Endpoints

| Method | Endpoint         | Description             |
| ------ | ---------------- | ----------------------- |
| GET    | `/health`        | Health check            |
| GET    | `/api/info`      | Application information |
| GET    | `/api/items`     | List all items          |
| GET    | `/api/items/:id` | Get specific item       |
| POST   | `/api/items`     | Create new item         |
| PUT    | `/api/items/:id` | Update item             |
| DELETE | `/api/items/:id` | Delete item             |

## Development Setup

### Install Dependencies

```bash
npm install
```

### Run Locally

```bash
npm run dev
```

### Run Tests

```bash
# Unit tests only (run in WSL)
npm test

# Integration tests only (run in Docker)
npm run test:integration

# All tests
npm run test:all
```

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

## Docker

### Build Image

```bash
docker build -t swarm-lab-app:1.0.0 .
```

### Run Container

```bash
docker run -p 3000:3000 -e NODE_ENV=production swarm-lab-app:1.0.0
```

## Testing

The application includes comprehensive test coverage:

- **Unit Tests**: Test individual API endpoints
- **Integration Tests**: Test complete workflows and edge cases
- **Coverage**: Minimum 70% code coverage required

Run tests in WSL for unit tests, and in Docker for integration tests to simulate the real deployment environment.
