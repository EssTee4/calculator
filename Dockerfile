# Stage 1: Build React frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /frontend

# Copy package.json and package-lock.json first for caching
COPY frontend/package*.json ./

# Install frontend dependencies
RUN npm install

# Copy all frontend source code
COPY frontend/ ./

# Fix OpenSSL issue for Node 18+
ENV NODE_OPTIONS=--openssl-legacy-provider

# Build frontend
RUN npm run build

# Stage 2: Build Python backend
FROM python:3.8-alpine

WORKDIR /app

# Install build dependencies for Python packages
RUN apk add --no-cache --update --virtual .build-deps \
    gcc python3-dev libffi-dev openssl-dev musl-dev

# Copy backend source code
COPY backend/ ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Remove build dependencies to reduce image size
RUN apk del .build-deps

# Copy frontend build from previous stage
COPY --from=frontend-builder /frontend/build /app/client

# Expose backend port
EXPOSE 5000

# Start backend with Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
