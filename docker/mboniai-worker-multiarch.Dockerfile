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