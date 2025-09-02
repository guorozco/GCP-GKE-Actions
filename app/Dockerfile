FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy application code
COPY app.py .

# Install Flask
RUN pip install flask

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=5000

# Expose port
EXPOSE 5000

# Add labels for better image management
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Hello World Flask app for GKE deployment"
LABEL version="1.0.0"

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/api/health')" || exit 1

# Run the application
CMD ["python", "app.py"]
