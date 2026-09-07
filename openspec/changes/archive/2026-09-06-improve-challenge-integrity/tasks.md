# Tasks

## 1. Offline-reproducible climax (R3)

- [x] 1.1 Rewrite `docs/WALKTHROUGH.md` Stage 5 breakout commands to use
  `python:3.12-slim-bookworm` (present in the outer engine from the inner build)
  instead of `alpine`.

## 2. Robust service startup (R6)

- [x] 2.1 Decouple `sshd` from the web entry in `docker-web/start.sh`: drop the
  `set -e` coupling, start `sshd` defensively so a hiccup cannot stop the Flask
  app from serving.

## 3. Protect the staged inner tree (R4)

- [x] 3.1 Tighten the `/opt/studio` permissions in `Dockerfile` from `go-w` to
  `go-rwx` so the outer `webdev` account cannot read staged inner secrets.

## 4. Reproducible build pins (R7)

- [x] 4.1 Pin `flask` and `jinja2` in `docker-web/web.Dockerfile` so the
  documented `cycler` gadget keeps resolving.

## 5. Walkthrough honesty and hosting-model note (R5)

- [x] 5.1 Update `docs/WALKTHROUGH.md` "Notes and red herrings" to state the
  socket mount yields outer root directly (SSH-as-`webdev` is a realism
  flourish) and to record the deploy-password build-history residual.
- [x] 5.2 Note the network-only intended hosting model in `README.md`.

## 6. Documentation

- [x] 6.1 Add a `CHANGELOG.md` entry dated 2026-09-06 summarizing the integrity
  fixes.
