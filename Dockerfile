FROM alpine:latest
# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/bin/tailscale
RUN mkdir -p /var/run/tailscale /var/lib/tailscale
# Add openssh
RUN apk add --no-cache openssh
# Setup tailscale
COPY tailscale.sh /tailscale.sh
RUN chmod +x /tailscale.sh
# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
