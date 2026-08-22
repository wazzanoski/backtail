FROM alpine:latest

# Environment variables
ENV USER=backtail
# Default permissions for Unraid
ENV PUID=99
ENV PGID=100
ENV UMASK=000

# System dependencies
RUN apk add --no-cache openssh shadow

# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/bin/tailscale
RUN mkdir -p /var/run/tailscale /var/lib/tailscale

# User/group creation moved to entrypoint.sh for runtime PUID/PGID support

# Setup sftp
COPY sftp_jail.conf /etc/ssh/sshd_config.d/
COPY run_sftp.sh /
COPY banner.txt /etc/ssh/
RUN chmod 500 /run_sftp.sh

# Setup tailscale
COPY run_tailscale.sh /
RUN chmod 500 /run_tailscale.sh

# Setup entrypoint
COPY logger.sh /
COPY entrypoint.sh /entrypoint.sh
RUN chmod 500 /logger.sh /entrypoint.sh

# Runtime configuration
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
