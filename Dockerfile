FROM alpine:latest

# Environment variables
ENV CONFIG_DIR="/config"
ENV USER="backtail"
ENV BACKUP_DIR="/data/${USER}"
# Default permissions for Unraid
ENV PUID=99
ENV PGID=100
ENV UMASK=000
# Dry run mode - validate configuration without starting services
ENV DRY_RUN=false
# Tailscale control - disable for testing/local networking
ENV TAILSCALE_ENABLED=true

RUN mkdir -p "${CONFIG_DIR}"
VOLUME "${CONFIG_DIR}"
RUN mkdir -p "${BACKUP_DIR}"
VOLUME "${BACKUP_DIR}"

# Remove unnecessary users & groups
RUN deluser nobody && delgroup nogroup
RUN deluser guest && delgroup users

# System dependencies
RUN apk add --no-cache openssh

# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable "/usr/local/bin/tailscaled" "/usr/bin/tailscaled"
COPY --from=docker.io/tailscale/tailscale:stable "/usr/local/bin/tailscale" "/usr/bin/tailscale"
RUN mkdir -p "/var/run/tailscale" "/var/lib/tailscale"

# User/group creation moved to entrypoint.sh for runtime PUID/PGID support

# Setup sftp
COPY "sftp_jail.conf" "/etc/ssh/sshd_config.d/"
COPY "run_sftp.sh" /
COPY "banner.txt" "/etc/ssh/"

# Setup tailscale
COPY "run_tailscale.sh" /

# Setup entrypoint
COPY "logger.sh" /
COPY "entrypoint.sh" /
COPY "healthcheck.sh" /

# Set permissions for all scripts in a single layer
RUN chmod 500 "/run_sftp.sh" "/run_tailscale.sh" "/logger.sh" "/entrypoint.sh" "/healthcheck.sh"

# Runtime configuration
EXPOSE 22

# Healthcheck
HEALTHCHECK --interval=30s --start-period=5s --timeout=3s --retries=3 \
  /healthcheck.sh || exit 1

ENTRYPOINT ["/entrypoint.sh"]
