# Express TypeScript Starter Template

A professional, production-ready Express.js backend starter template built with TypeScript, featuring clean architecture, comprehensive middleware, and best practices.

## ✨ Features

- ✅ **TypeScript** - Full type safety and modern JavaScript features
- ✅ **Clean Architecture** - Separation of concerns with layered structure
- ✅ **Error Handling** - Comprehensive error handling with custom error classes
- ✅ **Request Validation** - Schema-based validation using AJV
- ✅ **Rate Limiting** - Configurable rate limiting to prevent abuse
- ✅ **Security** - Security headers with Helmet
- ✅ **CORS** - Configurable cross-origin resource sharing
- ✅ **Logging** - HTTP request logging with Morgan
- ✅ **Health Checks** - Health, readiness, and liveness endpoints
- ✅ **Environment Config** - Environment-based configuration
- ✅ **ESLint** - Code quality and consistency
- ✅ **Docker Support** - Ready for containerization

## 📁 Project Structure

```
express-typescript-starter/
├── src/
│   ├── config/              # Configuration files
│   │   └── config.ts        # Environment and app configuration
│   ├── controllers/         # Request handlers
│   │   ├── health.controller.ts
│   │   └── user.controller.ts
│   │   └── index.ts
│   ├── middleware/          # Custom middleware
│   │   ├── errorHandler.ts
│   │   ├── notFoundHandler.ts
│   │   ├── rateLimiter.ts
│   │   └── validateRequest.ts
│   ├── routes/              # Route definitions
│   │   ├── index.ts
│   │   ├── health.routes.ts
│   │   └── user.routes.ts
│   ├── services/            # Business logic layer (add your services here)
│   ├── types/               # TypeScript type definitions
│   │   └── common.types.ts
│   ├── utils/               # Utility functions and helpers
│   │   ├── apiResponse.ts
│   │   ├── appError.ts
│   │   └── asyncErrorHandler.ts
│   ├── validation/          # Validation schemas
│   │   ├── index.ts
│   │   └── userSchema.ts    # User validation schema
│   ├── app.ts               # Express app setup
│   └── server.ts            # Server entry point
├── .env.example             # Example environment variables
├── .gitignore
├── Dockerfile               # Multi-stage Docker build
├── compose.yaml             # Docker Compose configuration
├── eslint.config.mts        # ESLint configuration
├── package.json
├── tsconfig.json            # TypeScript configuration
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn

### Installation

1. Clone or download this template:
   ```bash
   git clone https://github.com/Tushar1357/express-typescript-starter-template.git
   cd express-typescript-starter
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   ```bash
   cp .env.example .env
   ```

4. Configure your environment variables in `.env`

### Running the Application

**Development mode with hot reload:**
```bash
npm run dev
```

**Build for production:**
```bash
npm run build
```

**Start production server:**
```bash
npm start
```

**Lint code:**
```bash
npm run lint
```

**Fix linting issues:**
```bash
npm run lint:fix
```

## 📡 API Endpoints

### Health Check
- `GET /health` - Basic health check
- `GET /api/health` - Detailed health information
- `GET /api/health/readiness` - Readiness probe (for Kubernetes)
- `GET /api/health/liveness` - Liveness probe (for Kubernetes)

### Users (Example CRUD)
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30
  }
  ```
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

## 🏗️ Architecture

### Layered Architecture

1. **Routes Layer** (`src/routes/`)
   - Define API endpoints
   - Map HTTP methods to controller actions
   - Apply route-specific middleware

2. **Controllers Layer** (`src/controllers/`)
   - Handle HTTP requests and responses
   - Validate request data
   - Call service layer methods
   - Format responses using ApiResponse utility

3. **Services Layer** (`src/services/`)
   - Contain business logic
   - Interact with data models/databases
   - Handle data processing
   - *Add your service files here*

4. **Middleware Layer** (`src/middleware/`)
   - Request/response processing
   - Error handling
   - Validation
   - Rate limiting

5. **Utils Layer** (`src/utils/`)
   - Reusable utility functions
   - Custom error classes
   - Response formatters

## 🛠️ Key Technologies

- **Express.js** - Fast, unopinionated web framework
- **TypeScript** - Type safety and better developer experience
- **AJV** - JSON schema validation
- **Helmet** - Security headers
- **Morgan** - HTTP request logger
- **CORS** - Cross-origin resource sharing
- **http-status-codes** - HTTP status constants
- **express-rate-limit** - Rate limiting middleware

## 📝 Environment Variables

See `.env.example` for all available configuration options.

Key variables:
- `NODE_ENV` - Environment (development/production/test)
- `PORT` - Server port (default: 3000)
- `CORS_ORIGIN` - Allowed CORS origins (default: *)
- `API_PREFIX` - API route prefix (default: /api)
- `RATE_LIMIT_WINDOW_MS` - Rate limit window in milliseconds
- `RATE_LIMIT_MAX_REQUESTS` - Max requests per window

## 🔧 Customization Guide

### Adding a New Feature

1. **Create a controller** in `src/controllers/`
2. **Create routes** in `src/routes/`
3. **Add validation schema** in `src/validation/` (if needed)
4. **Create service** in `src/services/` for business logic
5. **Mount routes** in `src/routes/index.ts`

### Example: Adding a Blog Feature

```typescript
// src/controllers/blog.controller.ts
export const getAllPosts = asyncErrorHandler(async (req, res) => {
  const posts = await blogService.getAllPosts();
  return ApiResponse.success(res, posts);
});

// src/routes/blog.routes.ts
import { Router } from 'express';
import { getAllPosts } from '../controllers/blog.controller';

const router = Router();
router.get('/', getAllPosts);
export default router;

// src/routes/index.ts
import blogRoutes from './blog.routes';
router.use('/blog', blogRoutes);
```

## 🐳 Docker Support

This project includes a production-ready multi-stage Dockerfile and Docker Compose configuration.

### Prerequisites

- Docker (v20.10 or higher recommended)
- Docker Compose v2

### Docker Commands

**Start the application:**
```bash
npm run docker:start
```

**Stop the application:**
```bash
npm run docker:stop
```

**Restart the application:**
```bash
npm run docker:restart
```

Your application will be available at http://localhost:3000.

### Multi-Stage Build

The Dockerfile uses a multi-stage build for optimal image size:

1. **deps** - Installs production dependencies only
2. **build** - Installs all dependencies and builds TypeScript
3. **final** - Minimal runtime image with only production dependencies and compiled code

### Deploying to Cloud

1. Build for your target platform:
   ```bash
   # For amd64 (most cloud providers)
   docker build --platform=linux/amd64 -t myapp .
   ```

2. Tag and push to your registry:
   ```bash
   docker tag myapp myregistry.com/myapp:latest
   docker push myregistry.com/myapp:latest
   ```

### Adding Database Services

The `compose.yaml` includes a commented PostgreSQL example. Uncomment and configure as needed:

```yaml
services:
  server:
    depends_on:
      db:
        condition: service_healthy
  db:
    image: postgres
    # ... see compose.yaml for full configuration
```

## 🧪 Testing

*(Add your testing framework and tests)*

```bash
npm test
```

## 📄 License

MIT

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📚 Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [TypeScript Documentation](https://www.typescriptlang.org/)
- [AJV Documentation](https://ajv.js.org/)

## 💡 Tips

- Use the `asyncErrorHandler` wrapper for all async route handlers
- Always validate request data using schemas
- Use `ApiResponse` utility for consistent response formatting
- Throw `AppError` for operational errors
- Keep business logic in the service layer
- Add your database/ORM setup in the config folder
- Update rate limits based on your application needs

---

**Happy Coding! 🚀**
