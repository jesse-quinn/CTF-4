# Changelog

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
