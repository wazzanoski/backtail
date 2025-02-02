FROM alpine:latest
ENV USER=backtail
# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/bin/tailscale
RUN mkdir -p /var/run/tailscale /var/lib/tailscale
# Setup sftp
RUN apk add --no-cache openssh
COPY sftp_jail.conf /etc/ssh/sshd_config.d/
COPY run_sftp.sh /
COPY banner.txt /etc/ssh/
RUN chmod 500 /run_sftp.sh
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
COPY run_tailscale.sh /
RUN chmod 500 /run_tailscale.sh
# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod 500 /entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
