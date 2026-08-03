# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.14

FROM ghcr.io/astral-sh/uv:0.12.1-python${PYTHON_VERSION}-trixie-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Dependency layer: cached until pyproject.toml or uv.lock changes.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --locked --no-dev --no-install-project

COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

FROM python:${PYTHON_VERSION}-slim-trixie AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    DJANGO_SETTINGS_MODULE=config.settings

RUN groupadd --system --gid 1001 django \
    && useradd --system --uid 1001 --gid django --no-create-home django

WORKDIR /app

COPY --from=builder --chown=django:django /app /app

# Bake static assets into the image so no runtime step depends on them.
RUN DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput --clear \
    && chown -R django:django /app/staticfiles

USER django
EXPOSE 8000

# ECS runs its own container health check against this path via the ALB;
# this one covers `docker run` and local compose.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health/', timeout=2).status == 200 else 1)"

CMD ["gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "3", \
     "--threads", "2", \
     "--timeout", "60", \
     "--graceful-timeout", "30", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
