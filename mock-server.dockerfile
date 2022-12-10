FROM stoplight/prism:4

COPY build/bff-filtered.yaml /build/bff-filtered.yaml

# Add `-d` CLI flag to enable dynamic response generation (i.e. no examples)
ENTRYPOINT ["node", "/usr/local/bin/prism", "mock", "-h", "0.0.0.0", "/build/bff-filtered.yaml"]

EXPOSE 4010
