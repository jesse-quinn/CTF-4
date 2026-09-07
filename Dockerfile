FROM ubuntu:24.04

# Base packages for the outer CTF host: its own Docker engine plus sshd.
RUN apt-get update \
    && apt-get install -y docker.io docker-compose-v2 openssh-server nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Setup docker env + ssh env" \
    && mkdir -p /var/lib/docker /run/sshd \
    && sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config \
    && sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config \
    && ssh-keygen -A \
    && echo "Adding user webdev" \
    && useradd -m -s /bin/bash webdev \
    && echo -n "webdev:kZBrCqyOEkNIevVUrneXYt" | chpasswd \
    && userdel -r ubuntu \
    && echo "Linking .bash_history to /dev/null" \
    && ln -sf /dev/null /root/.bash_history \
    && ln -sf /dev/null /home/webdev/.bash_history

# Flags and the outer-host files.
COPY ./main_flags/root.txt /root/root.txt
COPY ./main_flags/user.txt /home/webdev/user.txt
COPY ./docker-web /opt/studio

# The deploy credential the socket-breakout stage recovers: webdev's own SSH
# password, kept root-only on the outer host. NOTE: this same password is set
# via chpasswd above, so it is recoverable from `docker history` of the built
# image. That is acceptable only for the intended network-only hosting model
# (see README "Hosting model"); do not distribute the built image.
RUN printf 'DEPLOY_HOST=studio-staging\nDEPLOY_USER=webdev\nDEPLOY_PASSWORD=kZBrCqyOEkNIevVUrneXYt\n' > /root/deploy.env

RUN echo "Permissions for flags" \
    && chown root:root /root/root.txt && chmod 0400 /root/root.txt \
    && chown webdev:webdev /home/webdev/user.txt && chmod 0400 /home/webdev/user.txt \
    && chown root:root /root/deploy.env && chmod 0600 /root/deploy.env \
    && echo "Permissions for the inner stack" \
    && chown -R root:root /opt/studio && chmod -R go-rwx /opt/studio

# Store the inner Docker engine's data on a volume so the nested engine does not
# run overlay-on-overlay (matches the official docker:dind image). Without this,
# inner image builds fail on hosts whose /var/lib/docker is itself an overlay
# filesystem (for example Docker Desktop).
VOLUME /var/lib/docker

EXPOSE 22 23 8080

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["docker", "compose", "-f", "/opt/studio/docker-compose.yaml", "up"]
