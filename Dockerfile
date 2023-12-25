FROM golang:1.21.1 as builder
ENV GOPROXY=https://goproxy.cn
RUN go install tailscale.com/cmd/derper@main

FROM ghcr.io/tailscale/tailscale:latest
WORKDIR /app
ENV DERP_DOMAIN your-hostname.com
ENV DERP_CERT_MODE letsencrypt
ENV DERP_CERT_DIR /app/certs
ENV DERP_ADDR :443
ENV DERP_STUN true
ENV DERP_STUN_PORT 3478
ENV DERP_HTTP_PORT 80
ENV DERP_VERIFY_CLIENTS false
COPY --from=builder /go/bin/derper .
COPY ./entrypoint.sh ./docker-entrypoint.sh
# Fix golang binary runtime error, clean cache and chmod
RUN mkdir /lib64 && ln -s /lib/ld-musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && rm -rf /var/cache/apk/* && rm -rf /root/.cache && rm -rf /tmp/* && chmod +x /app/docker-entrypoint.sh
ENTRYPOINT /app/docker-entrypoint.sh
