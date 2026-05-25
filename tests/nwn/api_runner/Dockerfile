FROM python:3.12-slim

WORKDIR /workspace

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Runtime content is mounted by docker-compose as a workspace volume.
# This image intentionally stays minimal (stdlib-only runner).
CMD ["python", "tests/nwn/api_runner/itnwn_api_server.py", "--host", "0.0.0.0", "--port", "51871", "--skip-nss-sync", "--skip-runner-compile", "--disable-app-capture"]
