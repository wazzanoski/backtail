FROM alpine:latest
# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/bin/tailscale
RUN mkdir -p /var/run/tailscale /var/lib/tailscale
# Setup sftp
RUN apk add --no-cache openssh
COPY sftp_jail.conf /etc/ssh/sshd_config.d/
COPY sftp_setup.sh /
RUN chmod +x /sftp_setup.sh
# Setup tailscale
COPY tailscale_setup.sh /
RUN chmod +x /tailscale_setup.sh
# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
