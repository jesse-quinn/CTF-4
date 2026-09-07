# Improve challenge integrity for Template Studio (CTF-4)

## Why

An adversarial review of the challenge on 2026-09-06 confirmed the intended
five-flag chain holds end to end (SSTI via `render_template_string(CARD % name)`
to RCE as `jinja`, reused `config.py` credential to `mako` over inner SSH,
`cap_setuid` Python copy to inner root, mounted outer `docker.sock` breakout to
both MAIN flags). The findings were refinements, not breakers, but several
degrade reproducibility, robustness, and hygiene:

- The documented final breakout pulls `alpine` at solve time, yet the README
  only promises internet access at first build. On a network-isolated host the
  climax fails and reads as a broken challenge.
- `docker-web/start.sh` runs under `set -e`, coupling the primary Flask web
  entry point to inner `sshd` startup: an `sshd` hiccup prevents the web app
  from serving at all.
- The inner stack staged at `/opt/studio` on the outer host is world-readable,
  so the unprivileged outer `webdev` account can read inner flag plaintext and
  the reused `mako` credential directly, bypassing the intended chain.
- Flask (and therefore Jinja2) is unpinned, so a future rebuild could drift onto
  a Jinja2 release where the documented `cycler.__init__.__globals__.os` gadget
  no longer resolves.
- The outer `webdev` / deploy password is baked into image build history via a
  `chpasswd` RUN line, a hazard only if the built image is distributed rather
  than hosted network-only; the intended hosting model is undocumented.

## What Changes

- **ADDED** requirement: offline-reproducible climax; the socket breakout reuses
  an image already present in the outer engine from the inner build
  (`python:3.12-slim-bookworm`) instead of pulling `alpine` at solve time.
- **ADDED** requirement: robust service startup; the primary web service is not
  coupled to `sshd` init success.
- **ADDED** requirement: the staged inner build tree under the outer host is not
  readable by the unprivileged outer account.
- **ADDED** requirement: reproducible build pins; Flask and Jinja2 are pinned so
  the documented gadget keeps resolving.
- **ADDED** requirement: walkthrough honesty about the socket primitive; the
  WALKTHROUGH states the mounted `docker.sock` yields outer root directly and
  the SSH-as-`webdev` step is a realism flourish, not load-bearing, and records
  the deploy-password build-history residual and the network-only hosting model.

## Impact

- Affected: documentation (`README.md`, `docs/WALKTHROUGH.md`, `CHANGELOG.md`)
  and challenge content (`Dockerfile`, `docker-web/start.sh`,
  `docker-web/web.Dockerfile`).
- No scoring or flag-value change: no flag file content is altered, and every
  flag remains reachable by its intended reader.
- No git commit is made; all edits are left uncommitted in the working tree.
