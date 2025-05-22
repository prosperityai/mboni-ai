#\!/bin/bash
set -e

# This script rebuilds MBONIAI Docker images on the EC2 instance
# with all customizations applied

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

echo "Cloning repository..."
git clone https://github.com/langgenius/dify.git
cd dify

echo "Applying MBONIAI customizations..."

# Create eyeball.png logo (simple base64 encoded placeholder)
echo "Creating eyeball logo..."
cat > eyeball.png.base64 << 'BASE64'
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
BASE64
base64 -d eyeball.png.base64 > eyeball.png

# 1. Update README.md to change Dify to MBONIAI
echo "Updating README.md..."
sed -i 's/Dify/MBONIAI/g' README.md
sed -i 's/dify\.ai/mboniai\.com/g' README.md

# 2. Update web components
echo "Updating web components..."

# Create metadata.tsx component to override page title and description
mkdir -p web/app/components
cat > web/app/components/metadata.tsx << 'METADATA'
'use client'

export default function Metadata() {
  return (
    <>
      <title>MBONIAI - AI Application Development Platform</title>
      <meta name="description" content="MBONIAI is an open-source LLM app development platform with intuitive interface for agentic AI workflow, RAG, and more." />
    </>
  )
}
METADATA

# Update logo component if it exists
if [ -f "web/app/components/base/logo/dify-logo.tsx" ]; then
  sed -i 's/Dify logo/MBONIAI logo/g' web/app/components/base/logo/dify-logo.tsx
fi

# 3. Update i18n files to remove community references
echo "Updating i18n files..."
find web/i18n -name "*.ts" -exec sed -i 's/join the community/join/g' {} \;
find web/i18n -name "*.ts" -exec sed -i 's/communityIntro: .*/communityIntro: "",/g' {} \;
find web/i18n -name "*.ts" -exec sed -i 's/roadmap: .*/roadmap: "",/g' {} \;

# Replace logo files
echo "Replacing logo files..."
mkdir -p web/public/logo
cp eyeball.png web/public/logo/logo-site.png
cp eyeball.png web/public/favicon.ico

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
