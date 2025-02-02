ENV USER=backtail
ENV CONFIG_DIR=/config

FROM alpine:latest
# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/bin/tailscale
RUN mkdir -p /var/run/tailscale /var/lib/tailscale
# Setup sftp
RUN apk add --no-cache openssh
COPY sftp_jail.conf /etc/ssh/sshd_config.d/
COPY sftp_setup.sh /
COPY banner.txt ${CONFIG}
RUN chmod +x /sftp_setup.sh
#log "Setting up sftp user..."
#-S              Create a system user
#-D              Don't assign a password
#-H              Don't create home directory
RUN adduser -S -D -H "${USER}"
#Because the account was created without a password
#the account is initially locked.
#https://unix.stackexchange.com/questions/193066/how-to-unlock-account-for-public-key-ssh-authorization-but-not-for-password-aut
#Unlock the account and set an invalid password hash:
RUN echo "${USER}:*" | chpasswd
# Setup tailscale
COPY tailscale_setup.sh /
RUN chmod +x /tailscale_setup.sh
# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
