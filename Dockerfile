#
# Build traefik-acme
# 
FROM golang:1.23.0-bookworm AS build

RUN go install github.com/na4ma4/traefik-acme/cmd/traefik-acme@v0.4.1; cp $(go env GOPATH)/bin/traefik-acme /

#
# Import kubectl
#
FROM d3fk/kubectl:v1.30 AS kubectl

#
# Resulting container
#
FROM debian:bookworm-slim

# Copy kubectl
COPY --from=kubectl /kubectl /usr/local/bin

# Copy traefik-acme
COPY --from=build /traefik-acme /usr/local/bin 

COPY ./bin/acmejson-to-secret.sh /usr/local/bin

CMD ["/usr/local/bin/acmejson-to-secret.sh"]