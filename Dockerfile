FROM xilinx-vivado:2025.1 AS base

# Python optimizations
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1

WORKDIR /app

FROM base AS builder

# cache dependencies w/ uv

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/
COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

FROM base AS prod

# copy app
WORKDIR /app
RUN chown ubuntu:ubuntu /app
COPY --chown=ubuntu ./ .

USER ubuntu

# get cached dependencies
COPY --from=builder /app/.venv /app/.venv

# Python env variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/"

# Vivado env variables
ENV VIVADO_VERSION=2025.1
ENV PATH="${XILINX_INSTALL_LOCATION}/${VIVADO_VERSION}/Vivado/bin:${PATH}"
ENV XILINX_LOCAL_USER_DATA=no

# run
CMD ["python3", "server.py"]
