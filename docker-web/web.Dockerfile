FROM python:3.12-slim-bookworm

ARG DOCKER_CLI_VERSION=27.5.1

# Base tooling: sshd for the lateral-movement step, libcap2-bin for the
# capability privesc, and curl/ca-certificates to fetch the static Docker client
# used in the final socket breakout.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server sudo libcap2-bin curl ca-certificates procps iproute2 \
    && pip install --no-cache-dir flask \
    && echo "Installing a static Docker CLI (used for the final socket breakout)" \
    && arch="$(uname -m)" \
    && curl -fsSL "https://download.docker.com/linux/static/stable/${arch}/docker-${DOCKER_CLI_VERSION}.tgz" -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /usr/local/bin --strip-components=1 docker/docker \
    && rm -f /tmp/docker.tgz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# App user (runs Flask) and the second, lateral-movement user.
RUN useradd -m -s /bin/bash jinja \
    && useradd -m -s /bin/bash mako \
    && echo "mako:Lpy6cWAdsi9WRcpEohd4uRR0" | chpasswd \
    && ln -sf /dev/null /home/jinja/.bash_history \
    && ln -sf /dev/null /home/mako/.bash_history \
    && ln -sf /dev/null /root/.bash_history

# The application. It is owned by jinja, who runs it; config.py (with the reused
# mako credential) is readable by the app user, which is exactly how command
# execution as jinja recovers the mako password.
COPY --chown=jinja:jinja ./app /app

# Flags. Each is read-only to its owner only.
COPY --chown=jinja:jinja --chmod=400 ./flags/jinja.txt /home/jinja/flag.txt
COPY --chown=mako:mako   --chmod=400 ./flags/mako.txt /home/mako/flag.txt
COPY --chown=root:root   --chmod=400 ./flags/template-root.txt /root/root.txt

# Privesc: a private copy of the Python interpreter, executable only by mako,
# carrying cap_setuid+cap_setgid. mako can drop to uid 0 with it; jinja cannot
# even execute it, so the mako step cannot be skipped.
RUN cp /usr/local/bin/python3.12 /usr/local/bin/pymgmt \
    && chown mako:mako /usr/local/bin/pymgmt \
    && chmod 0700 /usr/local/bin/pymgmt \
    && setcap cap_setuid,cap_setgid+ep /usr/local/bin/pymgmt

# sshd: password auth on, no direct root login.
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY --chmod=755 ./start.sh /start.sh

EXPOSE 8080 22

CMD ["/start.sh"]
