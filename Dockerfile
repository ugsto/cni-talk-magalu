FROM kindest/node:v1.32.2
USER root
RUN apt-get update && \
    apt-get install -y bridge-utils && \
    rm -rf /var/lib/apt/lists/*
