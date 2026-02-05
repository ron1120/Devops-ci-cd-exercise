FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=5000
ENV FLASK_ENV=production

# Install build deps (some packages may need a small toolchain)
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd -r app && useradd -r -g app app

WORKDIR /app

# Install Python dependencies first (takes advantage of Docker cache)
COPY requirements.txt ./
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Ensure permissions for the non-root user
RUN chown -R app:app /app

USER app

EXPOSE 5000

# Run using Gunicorn and the app factory defined in `main.py`
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "main:create_app()"]
