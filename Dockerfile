# Use the base image
FROM golang:alpine AS builder

# Install necessary tools
RUN apk update && apk add --no-cache \
    curl \
    tar  \
    jq

# Create a new working directory
WORKDIR /app

# Download and extract files, and give all users read, write, and execute permissions
RUN version=$(basename $(curl -sL -o /dev/null -w %{url_effective} https://github.com/pandora-next/deploy/releases/latest)) \
    && base_url="https://github.com/pandora-next/deploy/releases/expanded_assets/$version" \
    && latest_url="https://github.com/$(curl -sL $base_url | grep "href.*amd64.*\.tar.gz" | sed 's/.*href="//' | sed 's/".*//')" \
    && curl -Lo PandoraNext.tar.gz $latest_url \
    && tar -xzf PandoraNext.tar.gz --strip-components=1 \
    && rm PandoraNext.tar.gz \
    && chmod 777 -R .

# Get tokens.json
RUN --mount=type=secret,id=TOKENS_JSON,dst=/etc/secrets/TOKENS_JSON \
    if [ -f /etc/secrets/TOKENS_JSON ]; then \
    cat /etc/secrets/TOKENS_JSON > tokens.json \
    && chmod 777 tokens.json; \
    else \
    echo "TOKENS_JSON not found, skipping"; \
    fi

# Get config.json
RUN --mount=type=secret,id=CONFIG_JSON,dst=/etc/secrets/CONFIG_JSON \
    cat /etc/secrets/CONFIG_JSON > config.json && chmod 777 config.json

# Modify the execution permissions of PandoraNext
RUN chmod 777 ./PandoraNext

# Create a global cache directory and provide the most lenient permissions
RUN mkdir /.cache && chmod 777 /.cache

# Open port
EXPOSE 8181


# Start command with a loop for automatic restart
CMD ["sh", "-c", "while true; do ./PandoraNext; sleep 180; done"]