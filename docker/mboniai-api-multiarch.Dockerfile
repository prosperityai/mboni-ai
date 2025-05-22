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