# prebuild image to perform git clone, checkout and grab what we need for final image
# doesn't matter how we grab it, so we go small as possible here
FROM alpine:latest AS COMFY_CLONE

# build args for comfy-ui clone etc
# can be called as `docker build --build-arg COMFY_UI_CHECKOUT_HASH=<>`
ARG COMFY_UI_CHECKOUT_HASH="2bc12d3d22efb5c63ae3a7fc342bb2dd16b31735"

WORKDIR /opt

# alternate implementation for clone of single hash
# https://stackoverflow.com/questions/31278902/how-to-shallow-clone-a-specific-commit-with-depth-1
# however we use multi-stage builds here to make our life easier
RUN apk add git --no-cache && \
    git clone https://github.com/comfyanonymous/ComfyUI ComfyUI && \
    cd ComfyUI && \
    git checkout ${COMFY_UI_CHECKOUT_HASH} && \
    rm -rf .git

#
# Begin deploy image
#
FROM ubuntu:jammy AS deploy

USER root

# Install python
RUN sed -i 's|http://archive|http://au.archive|g' /etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3.10-venv && \
    apt-get clean && \
    sed -i 's|http://au.|http://|g' /etc/apt/sources.list

# Create non-root user
# and create location for appuser to do its thing. Install is an alternative to `mkdir && chmod`
RUN useradd --no-create-home --no-user-group --home-dir /nonexistent -u 5502 appuser && \
    install -d -m 0755 -o appuser -g root /app

USER appuser
WORKDIR /app

# Configure virtual environment.
ENV VIRTUAL_ENV=/app/.local/venv
RUN python3 -m venv ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

# Pip configuration and installation of dependencies
COPY requirements_aidreaming.txt /app/requirements.txt
RUN python3 -m pip install --no-cache-dir --upgrade pip wheel setuptools && \
    python3 -m pip install --no-cache-dir -r /app/requirements.txt && \
    rm /app/requirements.txt


# create location for modules & models to get into the image
RUN mkdir -p /app/modules /app/models
# Not sure if I should build these into the image or volume mount.
COPY models /app/models
COPY modules /app/modules

# Python program to run in the container
COPY --chown=appuser:root *.py /app/
COPY --chown=appuser:root LICENSE /app/

# workdir will also create the dir, how good
# we do this really late so that we can take advantage of docker's parallel building
WORKDIR /app/repositories
COPY --from=COMFY_CLONE --chown=appuser:root /opt/ComfyUI /app/repositories/ComfyUI-from-StabilityAI-Official

#cache loctions
ENV MPLCONFIGDIR=/app/.local/cache/matplotlib \
    TRANSFORMERS_CACHE=/app/.local/cache/huggingface/hub

WORKDIR /app
ENTRYPOINT [ "python3", "/app/launch.py", "--listen" ]
