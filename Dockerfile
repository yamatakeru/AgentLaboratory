# ----------------------------------------------------------
# Stage 1: Builder
# - Installs Python 3.12 and necessary build packages
# - Creates a virtual environment and installs dependencies
# ----------------------------------------------------------
FROM ghcr.io/astral-sh/uv:latest AS builder

# Use an unbuffered environment so Python output appears instantly
ENV PYTHONUNBUFFERED=1

# Update and install build-essential and other tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    texlive-latex-base \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only requirements first for efficient Docker layer caching
COPY requirements.txt ./

# Create virtual environment and install dependencies:
# - If pyproject.toml exists: use uv sync
# - If pyproject.toml does not exist: install from requirements.txt
RUN if [ -f "pyproject.toml" ]; then \
        uv sync \
    else \
        uv init \
        && uv add -r -no-cache requirements.txt \
    fi

# Now copy the entire repository
COPY . .

# Optional: If your project has a formal setup script you could do:
# RUN . /opt/venv/bin/activate && python setup.py install
# But here we assume `requirements.txt` is enough.

# ----------------------------------------------------------
# Stage 2: Runner
# - Copies in the pre-installed virtual environment
# - Provides a minimal runtime environment
# ----------------------------------------------------------
FROM ghcr.io/astral-sh/uv:latest AS runner

# Again, no buffering
ENV PYTHONUNBUFFERED=1

# Copy the installed venv from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Create a user for security best-practices (optional but recommended)
RUN adduser --disabled-password --gecos '' agentuser

# Set the user to the newly created non-root user
USER agentuser

# Set working directory and copy code
WORKDIR /app
COPY --chown=agentuser:agentuser . .

# Add the virtual environment to PATH
ENV PATH="/opt/venv/bin:$PATH"

# (Optional) If you do not want to compile LaTeX on the runtime stage,
# comment out the installation below. Otherwise, keep it if you plan to do LaTeX compilation.
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    && rm -rf /var/lib/apt/lists/*

# By default, we run the main Python script
# You can override CMD in docker-compose or `docker run`
CMD ["uv", "run", "ai_lab_repo.py", "--api-key", "API_KEY_HERE", "--llm-backend", "o1-mini", "--compile-latex", "false", "--config-path", "config/task_notes.yml"]
