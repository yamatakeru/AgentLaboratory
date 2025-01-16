FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN adduser --disabled-password --gecos '' agentuser

# Set up the application
WORKDIR /app
COPY --chown=agentuser:agentuser . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

USER agentuser

CMD ["python", "ai_lab_repo.py", "--api-key", "API_KEY_HERE", "--llm-backend", "o1-mini", "--compile-latex", "false", "--config-path", "config/task_notes.yml"]
