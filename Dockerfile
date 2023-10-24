FROM elixir:1.14-otp-25-slim as build

# Install deps
RUN set -xe; \
    apt-get update && \
    apt-get install -y \
        ca-certificates \
        build-essential \
        git \
        libcrypt-dev;

# Use the standard /usr/local/src destination
RUN mkdir -p /usr/local/src/assembly

COPY . /usr/local/src/assembly/

# ARG is available during the build and not in the final container
# https://vsupalov.com/docker-arg-vs-env/
ARG MIX_ENV=prod
ARG APP_NAME=assembly

# Use `set -xe;` to enable debugging and exit on error
# More verbose but that is often beneficial for builds
RUN set -xe; \
    cd /usr/local/src/assembly/; \
    mix local.hex --force; \
    mix local.rebar --force; \
    mix deps.get; \
    mix deps.compile --all; \
    mix release

FROM debian:11.6-slim as release

RUN set -xe; \
    apt-get update &&  \
    apt-get install -y  \
        ca-certificates \
        libmcrypt4 \
        libncurses5-dev;

# Create a `assembly` group & user
# I've been told before it's generally a good practice to reserve ids < 1000 for the system
RUN set -xe; \
    adduser --uid 1000 --system --home /assembly --shell /bin/sh --group assembly;

ARG APP_NAME=assembly

# Copy the release artifact and set `assembly` ownership
COPY --chown=assembly:assembly --from=build /usr/local/src/assembly/_build/prod/rel/${APP_NAME} /assembly

# These are fed in from the build script
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

# `Maintainer` has been deprecated in favor of Labels / Metadata
# https://docs.docker.com/engine/reference/builder/#maintainer-deprecated
LABEL \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="assembly" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/system76/assembly" \
    org.opencontainers.image.title="assembly" \
    org.opencontainers.image.vendor="system76" \
    org.opencontainers.image.version="${VERSION}"

ENV \
    PATH="/usr/local/bin:$PATH" \
    VERSION="${VERSION}" \
    APP_REVISION="${VERSION}" \
    MIX_APP="assembly" \
    MIX_ENV="prod" \
    SHELL="/bin/bash" \
    LANG="C.UTF-8"

# Drop down to our unprivileged `assembly` user
USER assembly

WORKDIR /assembly

EXPOSE 50051

ENTRYPOINT ["/assembly/bin/assembly"]

CMD ["start"]
