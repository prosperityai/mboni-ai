# MBONIAI Deployment Guide

This document provides a comprehensive guide to deploying the MBONIAI platform, which is based on the Dify.AI framework.

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Troubleshooting](#troubleshooting)

## Overview

MBONIAI is an AI application development platform that allows you to build, deploy, and manage AI applications with a focus on ease of use and extensibility. It's based on the Dify.AI open-source project and has been customized for specific needs.

## System Architecture

The MBONIAI platform consists of the following components:

### Core Components

1. **Web Interface** - Next.js frontend application that provides the UI for managing and interacting with AI apps.
2. **API Service** - Flask-based backend service that handles API requests, manages data, and integrates with AI providers.
3. **Worker** - Celery worker that processes background tasks like document indexing and email sending.
4. **Plugin Daemon** - Service that manages the lifecycle of plugins and extensions.

### Infrastructure Components

1. **PostgreSQL Database** - Stores application data, user information, and configuration.
2. **Redis** - Used for caching, session management, and as a message broker for Celery.

### Integration Components

1. **AI Model Providers** - Integration with AI providers like OpenAI, Anthropic, etc.
2. **Storage Services** - For storing files and documents (local storage by default).

## Requirements

### Hardware Requirements

- CPU: 2+ cores
- RAM: 4GB+ (8GB+ recommended)
- Storage: 10GB+ for application data and Docker images

### Software Requirements

- Docker and Docker Compose
- Git (for cloning the repository)
- Internet connection (for pulling Docker images and connecting to AI providers)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/mboni-ai.git
cd mboni-ai
```

### 2. Configure Environment

Create a minimal deployment using the `docker-compose.minimal.yaml` file:

```bash
# Create necessary directories
mkdir -p volumes/app/storage volumes/db/data volumes/redis/data volumes/plugin_daemon
```

### 3. Deploy with Docker Compose

```bash
docker-compose -f docker-compose.minimal.yaml up -d
```

This will start the following services:
- Web interface on port 3000
- API service on port 5001
- PostgreSQL database on port 5432
- Redis on port 6379
- Plugin Daemon on port 5002

## Configuration

### Basic Configuration

The platform is configured through environment variables in the `docker-compose.minimal.yaml` file:

```yaml
version: '3'

services:
  api:
    image: langgenius/dify-api:1.4.0
    environment:
      - DB_USERNAME=postgres
      - DB_PASSWORD=difyai123456
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=dify
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=difyai123456
      - REDIS_USE_SSL=false
      - CONSOLE_API_URL=http://localhost:5001
      - APP_API_URL=http://localhost:5001
      - SERVICE_API_URL=http://localhost:5001
      - CONSOLE_WEB_URL=http://localhost:3000
      - APP_WEB_URL=http://localhost:3000
      - STORAGE_TYPE=local
      - STORAGE_LOCAL_PATH=/app/api/storage
      - SECRET_KEY=sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U
      - WEB_API_CORS_ALLOW_ORIGINS=http://localhost:3000
      - CONSOLE_CORS_ALLOW_ORIGINS=http://localhost:3000
      - MIGRATION_ENABLED=true
      - PLUGINS_ENABLE=true
      - PLUGIN_DAEMON_ENABLED=true
      - PLUGIN_DAEMON_HOST=plugin_daemon
      - PLUGIN_DAEMON_URL=http://plugin_daemon:5002
      - PLUGIN_DAEMON_PORT=5002
      - PLUGIN_DAEMON_KEY=lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi
      - DIFY_INNER_API_KEY=QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1
      - CELERY_BROKER_URL=redis://:difyai123456@redis:6379/0
      - CELERY_RESULT_BACKEND=redis://:difyai123456@redis:6379/0
    volumes:
      - ./volumes/app/storage:/app/api/storage
    ports:
      - "5001:5001"
    depends_on:
      - db
      - redis
      - plugin_daemon

  web:
    image: langgenius/dify-web:1.4.0
    environment:
      - CONSOLE_API_URL=http://localhost:5001
      - APP_API_URL=http://localhost:5001
      - NEXT_PUBLIC_APP_NAME=MBONIAI
      - NEXT_PUBLIC_SITE_TITLE=MBONIAI - AI Application Development Platform
    ports:
      - "3000:3000"
    depends_on:
      - api

  worker:
    image: langgenius/dify-api:1.4.0
    working_dir: /app/api
    entrypoint: []
    command: ["/app/api/.venv/bin/celery", "-A", "app.celery", "worker", "--loglevel=info"]
    environment:
      - DB_USERNAME=postgres
      - DB_PASSWORD=difyai123456
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=dify
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=difyai123456
      - REDIS_USE_SSL=false
      - CELERY_BROKER_URL=redis://:difyai123456@redis:6379/0
      - CELERY_RESULT_BACKEND=redis://:difyai123456@redis:6379/0
      - CONSOLE_API_URL=http://localhost:5001
      - APP_API_URL=http://localhost:5001
      - SERVICE_API_URL=http://localhost:5001
      - CONSOLE_WEB_URL=http://localhost:3000
      - APP_WEB_URL=http://localhost:3000
      - STORAGE_TYPE=local
      - STORAGE_LOCAL_PATH=/app/api/storage
      - SECRET_KEY=sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U
      - PLUGINS_ENABLE=true
      - PLUGIN_DAEMON_ENABLED=true
      - PLUGIN_DAEMON_HOST=plugin_daemon
      - PLUGIN_DAEMON_URL=http://plugin_daemon:5002
      - PLUGIN_DAEMON_PORT=5002
      - PLUGIN_DAEMON_KEY=lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi
      - DIFY_INNER_API_KEY=QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1
    volumes:
      - ./volumes/app/storage:/app/api/storage
    depends_on:
      - db
      - redis
      - plugin_daemon

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=difyai123456
      - POSTGRES_DB=dify
    volumes:
      - ./volumes/db/data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:6-alpine
    command: redis-server --requirepass difyai123456
    volumes:
      - ./volumes/redis/data:/data
    ports:
      - "6379:6379"
      
  plugin_daemon:
    image: langgenius/dify-plugin-daemon:0.0.10-local
    volumes:
      - ./volumes/plugin_daemon:/app/storage
    ports:
      - "5002:5002"
    environment:
      # Basic settings
      - SERVER_KEY=lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi
      - SERVER_PORT=5002
      # Database connection
      - DB_USERNAME=postgres
      - DB_PASSWORD=difyai123456
      - DB_HOST=db
      - DB_PORT=5432
      - DB_DATABASE=dify_plugin
      # Redis connection
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=difyai123456
      - REDIS_USE_SSL=false
      # Dify integration
      - DIFY_INNER_API_KEY=QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1
      - DIFY_INNER_API_URL=http://api:5001
      # Storage configuration
      - STORAGE_TYPE=local
      - STORAGE_LOCAL_ROOT=/app/storage
      - PLUGIN_WORKING_PATH=/app/storage/cwd
      - PLUGIN_INSTALLED_PATH=plugin
      - PLUGIN_PACKAGE_CACHE_PATH=plugin_packages
      - PLUGIN_MEDIA_CACHE_PATH=assets
      # Plugin settings
      - PLUGIN_MAX_PACKAGE_SIZE=52428800
      - PLUGIN_MAX_EXECUTION_TIMEOUT=600
      - PLUGIN_PYTHON_ENV_INIT_TIMEOUT=120
      - FORCE_VERIFYING_SIGNATURE=false
      - PLUGIN_PPROF_ENABLED=false
      # Remote installing
      - PLUGIN_REMOTE_INSTALLING_HOST=0.0.0.0
      - PLUGIN_REMOTE_INSTALLING_PORT=5003
```

### Configuring AI Providers

After deployment, you need to configure at least one AI model provider:

1. Access the web interface at http://localhost:3000
2. Complete the initial setup and create an account
3. Go to Settings > Model Providers
4. Add and configure a provider (e.g., OpenAI, Anthropic)
5. Enter your API key for the provider

## Troubleshooting

### Common Issues

#### 1. Database Connection Issues

If the API service cannot connect to the database, check:
- PostgreSQL container is running (`docker ps`)
- Database credentials are correct in the configuration
- Database port is accessible

#### 2. Worker Not Processing Tasks

If background tasks are not being processed, check:
- Celery worker container is running
- Redis connection is working
- Broker URL and Result Backend URL are correctly configured

#### 3. Plugin Daemon Connection Issues

If the API cannot connect to the plugin daemon, check:
- Plugin daemon container is running
- Plugin daemon port is accessible
- Plugin daemon configuration is correct

#### 4. CORS Errors

If you encounter CORS errors when accessing the API from the web interface, check:
- CORS_ALLOW_ORIGINS environment variables are set correctly
- API URLs are configured correctly in both API and Web services

### Database Fixes

Sometimes you may need to manually update the database to fix configuration issues:

```sql
-- Example: Update app model configuration to use OpenAI provider
UPDATE app_model_configs 
SET provider = 'langgenius/openai/openai', 
    model = '{"provider": "langgenius/openai/openai", "name": "gpt-4o-2024-11-20", "mode": "chat", "completion_params": {}}' 
WHERE app_id = 'your-app-id';
```

## Production Deployment

For production deployment, consider the following additional steps:

1. Use proper SSL/TLS certificates
2. Set up a reverse proxy (e.g., Nginx)
3. Use a proper domain name
4. Implement backups for database and storage
5. Consider using managed databases instead of containerized ones
6. Scale worker processes based on your workload
7. Implement monitoring and alerting

## Security Considerations

1. Change all default passwords and keys
2. Restrict access to admin interfaces
3. Use a firewall to limit access to services
4. Regularly update the software
5. Implement proper authentication and authorization
6. Secure API keys and secrets

---

For more information, visit the Dify documentation at https://docs.dify.ai/