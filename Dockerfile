# Build stage
FROM node:20-slim AS builder

# Install build dependencies for canvas and other native modules
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    pkg-config \
    libcairo2-dev \
    libjpeg-dev \
    libpango1.0-dev \
    libgif-dev \
    librsvg2-dev \
    findutils \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy configuration files
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY artifacts/anki-generator/package.json ./artifacts/anki-generator/
COPY artifacts/api-server/package.json ./artifacts/api-server/

# Copy all lib packages (we need their package.json for install)
COPY lib/ ./lib/
RUN find lib -type f ! -name "package.json" -delete

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the code
COPY . .

# Set environment variables for build
ENV PORT=10000
ENV BASE_PATH=/
ENV NODE_ENV=production

# Build all packages
RUN pnpm run build

# Run stage
FROM node:20-slim

# Install runtime dependencies for canvas
RUN apt-get update && apt-get install -y \
    libcairo2 \
    libjpeg62-turbo \
    libpango-1.0-0 \
    libgif7 \
    librsvg2-2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy necessary files from the builder
COPY --from=builder /app /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=10000

EXPOSE 10000

# Start the server
CMD ["pnpm", "--filter", "@workspace/api-server", "run", "start"]

