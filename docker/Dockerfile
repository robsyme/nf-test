# Tooling image for Fusion filesystem probes and minimal reproducible examples.
#
# The reason this image exists: Nextflow's task wrapper calls `ps` to collect
# task metrics, and on a base image without procps the task dies with exit 1,
# no script output whatsoever, and a single warning that reads as harmless -
# "Command 'ps' required by nextflow to collect task metrics cannot be found".
# Nothing indicates the task never started. That cost four Platform runs to
# diagnose, so procps is pinned in here deliberately.
#
# Also carries an S3 client, because reading S3 ground truth from inside a
# Fusion task is the only way to see what the object store actually holds -
# querying through the mount returns Fusion's cached view, which is the very
# thing under investigation. The official aws-cli images cannot be used for
# this: their ENTRYPOINT is ["aws"], which swallows the Nextflow task script.
FROM python:3.12-slim

ARG AWSCLI_VERSION=1.46.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        procps \
        jq \
        curl \
        unzip \
        findutils \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "awscli==${AWSCLI_VERSION}"

# Fail the build rather than publish an image that is missing something a task
# needs. Every one of these has been a real failure at some point.
RUN set -eu; \
    for c in ps python3 bash aws jq curl dd tr find sed awk; do \
        command -v "$c" >/dev/null || { echo "FATAL: $c missing from image"; exit 1; }; \
    done; \
    aws --version; \
    python3 --version; \
    ps --version | head -1

# No ENTRYPOINT on purpose: Nextflow needs to run its own task script.
CMD ["/bin/bash"]
