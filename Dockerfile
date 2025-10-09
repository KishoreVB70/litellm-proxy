FROM ghcr.io/berriai/litellm:main-stable

WORKDIR /app

COPY litellm_config.yaml /app/config.yaml

EXPOSE 4000

CMD ["--port", "4000", "--config", "/app/config.yaml"]
