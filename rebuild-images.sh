#\!/bin/bash
set -e

# This script rebuilds MBONIAI Docker images on the EC2 instance
# to ensure they are compatible with the EC2 architecture (amd64)

echo "Setting up environment variables..."
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export API_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mboniai-api"
export WEB_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mboniai-web"
export WORKER_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mboniai-worker"

echo "Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Creating temp directory to store Dockerfiles..."
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# ========== API Image ==========
echo "Creating API Dockerfile..."
cat > Dockerfile.api << 'DOCKERFILE'
FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN pip install poetry==1.6.1

# Copy API code
COPY ./api /app/

# Configure poetry to not use virtualenv
RUN poetry config virtualenvs.create false

# Install dependencies
RUN cd /app && poetry install --only main --no-interaction --no-ansi

# Set environment variables
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py
ENV FLASK_DEBUG=0

# Expose ports
EXPOSE 5001

# Start API
CMD ["bash", "-c", "cd /app && gunicorn -c gunicorn_config.py app:app"]
DOCKERFILE

# Try to get API code from GitHub if available
echo "Downloading MBONIAI source code..."
if curl -s -o mboniai.zip https://codeload.github.com/langgenius/dify/zip/refs/heads/main; then
  echo "Downloaded from GitHub"
  unzip -q mboniai.zip
  mkdir -p api
  cp -r dify-main/api/* api/
  rm -rf dify-main mboniai.zip
else
  echo "Failed to download source code, please provide it manually"
  exit 1
fi

echo "Building API image..."
docker build -f Dockerfile.api -t $API_REPO:latest .
echo "Pushing API image to ECR..."
docker push $API_REPO:latest

# ========== Web Image ==========
echo "Creating Web Dockerfile..."
cat > Dockerfile.web << 'DOCKERFILE'
FROM node:18-alpine AS builder

WORKDIR /app

# Copy web code
COPY ./web /app/

# Install dependencies
RUN yarn install

# Build application
RUN yarn build

FROM node:18-alpine

WORKDIR /app

# Copy built application
COPY --from=builder /app/.next /app/.next
COPY --from=builder /app/public /app/public
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/package.json /app/

# Copy needed files
COPY ./web/next.config.js /app/
COPY ./web/docker /app/docker

# Expose port
EXPOSE 3000

# Start web server
CMD ["node_modules/.bin/next", "start"]
DOCKERFILE

mkdir -p web
cp -r dify-main/web/* web/

echo "Building Web image..."
docker build -f Dockerfile.web -t $WEB_REPO:latest .
echo "Pushing Web image to ECR..."
docker push $WEB_REPO:latest

# ========== Worker Image ==========
echo "Creating Worker Dockerfile..."
cat > Dockerfile.worker << 'DOCKERFILE'
FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN pip install poetry==1.6.1

# Copy worker code
COPY ./api /app/

# Configure poetry to not use virtualenv
RUN poetry config virtualenvs.create false

# Install dependencies
RUN cd /app && poetry install --only main --no-interaction --no-ansi

# Set environment variables
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py
ENV FLASK_DEBUG=0

# Start worker
CMD ["celery", "-A", "app.celery", "worker", "-P", "solo", "-c", "1", "-l", "info", "-E"]
DOCKERFILE

echo "Building Worker image..."
docker build -f Dockerfile.worker -t $WORKER_REPO:latest .
echo "Pushing Worker image to ECR..."
docker push $WORKER_REPO:latest

echo "Creating docker-compose.yaml file..."
cat > docker-compose.yaml << 'COMPOSE'
version: '3'

services:
  api:
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mboniai-api:latest
    restart: always
    environment:
      # Database
      - DB_USERNAME=postgres
      - DB_PASSWORD=YOUR_PASSWORD
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=mboniai
      # Redis
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_USERNAME=
      - REDIS_PASSWORD=
      - REDIS_USE_SSL=False
      # Web
      - WEB_API_URL=http://localhost/api
      - CONSOLE_API_URL=http://localhost/console/api
    ports:
      - "5001:5001"
    depends_on:
      - postgres
      - redis

  worker:
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mboniai-worker:latest
    restart: always
    environment:
      # Database
      - DB_USERNAME=postgres
      - DB_PASSWORD=YOUR_PASSWORD
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=mboniai
      # Redis
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_USERNAME=
      - REDIS_PASSWORD=
      - REDIS_USE_SSL=False
      # Web
      - WEB_API_URL=http://localhost/api
      - CONSOLE_API_URL=http://localhost/console/api
    depends_on:
      - api
      - postgres
      - redis

  web:
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mboniai-web:latest
    restart: always
    environment:
      - NODE_ENV=production
      - EDITION=SELF_HOSTED
      - CONSOLE_API_URL=http://api:5001
      - WEB_API_URL=http://api:5001
    ports:
      - "3000:3000"
    depends_on:
      - api

  postgres:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=YOUR_PASSWORD
      - POSTGRES_DB=mboniai
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:6-alpine
    restart: always
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - api
      - web

volumes:
  postgres-data:
  redis-data:
COMPOSE

echo "Creating nginx.conf..."
cat > nginx.conf << 'NGINX'
server {
    listen 80;
    server_name _;

    # Web frontend
    location / {
        proxy_pass http://web:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API endpoints
    location /api {
        proxy_pass http://api:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Console API endpoints
    location /console/api {
        rewrite ^/console/api/(.*) /api/$1 break;
        proxy_pass http://api:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

echo "Moving files to /home/ubuntu/mboniai..."
mkdir -p /home/ubuntu/mboniai
cp docker-compose.yaml nginx.conf /home/ubuntu/mboniai/

echo "Cleanup..."
cd /home/ubuntu
rm -rf $TEMP_DIR

echo "====================================================="
echo "All images rebuilt and pushed to ECR successfully\!"
echo "To start the application:"
echo "  1. Change to the application directory: cd /home/ubuntu/mboniai"
echo "  2. Start the containers: docker-compose up -d"
echo "====================================================="
