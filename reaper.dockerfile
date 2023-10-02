# define base image
FROM ubuntu:jammy

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

# Python program to run in the container
COPY reaper.py /app/reaper.py

ENTRYPOINT [ "python3", "/app/reaper.py" ]
