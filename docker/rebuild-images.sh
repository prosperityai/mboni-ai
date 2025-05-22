#!/bin/bash
set -e

# This script builds MBONIAI Docker images on the EC2 instance
# to ensure they are compatible with the EC2 architecture (amd64)

echo "Creating temporary directory..."
mkdir -p /tmp/mboniai-rebuild

echo "Downloading eyeball.png from S3..."
aws s3 cp s3://public-resources-bucket/eyeball.png /tmp/mboniai-rebuild/ || {
  echo "Failed to download eyeball.png from S3. Using a different approach..."
  curl -o /tmp/mboniai-rebuild/eyeball.png https://raw.githubusercontent.com/mboniai/assets/main/eyeball.png || {
    echo "Creating a placeholder eyeball.png..."
    # Create a simple logo file if download fails
    echo "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" | base64 -d > /tmp/mboniai-rebuild/eyeball.png
  }
}

echo "Creating Dockerfiles..."

# Create Dockerfile for API
cat > /tmp/mboniai-rebuild/Dockerfile.api << 'EOF'
FROM langgenius/dify-api:1.4.0

LABEL maintainer="MBONIAI"
LABEL description="MBONIAI API Service - Customized from Dify"

# Copy our custom logo into the container
COPY eyeball.png /app/api/dify_app/public/logo.png

# Set environment variables for branding
ENV APP_NAME="MBONIAI"
ENV APP_DESCRIPTION="MBONIAI - AI Application Development Platform"

# Default command from original image
ENTRYPOINT ["/entrypoint.sh"]
EOF

# Create Dockerfile for Web
cat > /tmp/mboniai-rebuild/Dockerfile.web << 'EOF'
FROM langgenius/dify-web:1.4.0

LABEL maintainer="MBONIAI"
LABEL description="MBONIAI Web Service - Customized from Dify"

# Copy our custom logo to replace the original logo files
COPY eyeball.png /app/web/public/logo/logo-site.png
COPY eyeball.png /app/web/public/logo/logo-site-dark.png
COPY eyeball.png /app/web/public/logo/logo.svg
COPY eyeball.png /app/web/public/logo/logo-monochrome-white.svg
COPY eyeball.png /app/web/public/logo/logo-embedded-chat-avatar.png
COPY eyeball.png /app/web/public/logo/logo-embedded-chat-header.png
COPY eyeball.png /app/web/public/logo/logo-embedded-chat-header@2x.png
COPY eyeball.png /app/web/public/logo/logo-embedded-chat-header@3x.png
COPY eyeball.png /app/web/public/favicon.ico

# Environment variables for branding
ENV NEXT_PUBLIC_APP_NAME="MBONIAI"
ENV NEXT_PUBLIC_SITE_TITLE="MBONIAI - AI Application Development Platform"

# Default command from original image
ENTRYPOINT ["/app/web/entrypoint.sh"]
EOF

# Create Dockerfile for Worker
cat > /tmp/mboniai-rebuild/Dockerfile.worker << 'EOF'
FROM langgenius/dify-api:1.4.0

LABEL maintainer="MBONIAI"
LABEL description="MBONIAI Worker Service - Customized from Dify"

# Copy our custom logo into the container
COPY eyeball.png /app/api/dify_app/public/logo.png

# Set environment variables for branding
ENV APP_NAME="MBONIAI"
ENV APP_DESCRIPTION="MBONIAI - AI Application Development Platform"

# Override entrypoint to run as worker
ENTRYPOINT ["celery", "-A", "app.celery", "worker", "-P", "gevent", "-c", "1", "--loglevel=INFO", "-Q", "dataset,generation,mail,ops_trace,app_deletion"]
EOF

echo "Building Docker images..."
cd /tmp/mboniai-rebuild

# Build API image
echo "Building API image..."
docker build -t 533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-api:latest -f Dockerfile.api .

# Build Web image
echo "Building Web image..."
docker build -t 533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-web:latest -f Dockerfile.web .

# Build Worker image
echo "Building Worker image..."
docker build -t 533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-worker:latest -f Dockerfile.worker .

echo "Logging into ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 533267319731.dkr.ecr.us-east-1.amazonaws.com

echo "Pushing images to ECR..."
docker push 533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-api:latest
docker push 533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-web:latest
docker push 533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-worker:latest

echo "Cleanup..."
rm -rf /tmp/mboniai-rebuild

echo "Done! Now you can run docker-compose up -d in your mboniai directory."