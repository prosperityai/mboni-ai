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