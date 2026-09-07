# Changelog

## 2026-09-06 - Challenge integrity fixes

Refinements from an adversarial review; no flag values or scoring changed, and
every flag remains reachable by its intended reader.

- Final socket breakout no longer pulls `alpine` at solve time. The walkthrough
  now uses `python:3.12-slim-bookworm` (the inner web base, already present in
  the outer engine from the inner build), so the climax works with no outbound
  network, matching what the README promised.
- `docker-web/start.sh` no longer couples the Flask web entry point to inner
  `sshd` startup: `set -e` was dropped and `sshd` is started defensively, so a
  sshd hiccup can no longer stop the web app from serving.
- The staged inner stack at `/opt/studio` on the outer host is tightened from
  `go-w` to `go-rwx`, so the unprivileged outer `webdev` account can no longer
  read inner flag plaintext or the reused `mako` credential directly.
- Flask and Jinja2 are pinned (`flask==3.1.3`, `jinja2==3.1.6`) so the
  documented `cycler.__init__.__globals__.os` SSTI gadget keeps resolving across
  rebuilds.
- Documented the intended network-only hosting model in the README and recorded
  two known residuals in the walkthrough notes: the mounted `docker.sock` reads
  both outer flags directly (the SSH-as-`webdev` step is a realism flourish, not
  a gate), and the outer deploy password is present in the image build history.

## Initial release

Original docker-in-docker CTF themed on Server-Side Template Injection in a Flask
and Jinja2 web application. The design follows the docker-in-docker pattern of
the Himanshukr000/CTF-DOCKERS collection: one privileged outer host runs its own
Docker engine and deploys the vulnerable inner stack with Docker Compose.

### Challenge chain

- Flask "Template Studio" renders greeting cards by interpolating the visitor
  supplied name into a template string and passing it to
  `render_template_string`, giving Server-Side Template Injection. `{{7*7}}`
  confirms it.
- The injection is escalated to remote code execution as the app user `jinja`
  through the Jinja2 sandbox-escape globals, yielding the first inner flag.
- The app config file carries a reused deploy credential (the same password as
  the `mako` system account), which is read through the RCE and used to log in
  as `mako` over the inner SSH service, yielding the second inner flag.
- `mako` owns a private copy of the Python interpreter carrying
  `cap_setuid,cap_setgid`, discoverable with `getcap`. It drops to uid 0 for a
  root shell in the web container, yielding the inner-root `TEMPLATE_FLAG`.
- Inner root abuses the mounted outer Docker socket with a static Docker client
  to run a container that mounts the outer host filesystem. That reads the outer
  root flag and recovers the outer `webdev` password from a root-only deploy
  file; `webdev` then serves the outer user flag over the outer SSH service.

### Build hygiene

- The inner base image and the static Docker client are pulled at build time, so
  the challenge is multi-arch (amd64 and arm64) with no baked image tarballs.
- The outer Dockerfile declares `VOLUME /var/lib/docker` so the nested Docker
  engine does not run overlay-on-overlay.
- `.dockerignore` keeps the git history, docs, license, and readme out of the
  build context and image layers.
