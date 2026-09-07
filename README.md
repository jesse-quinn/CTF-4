# Template Studio CTF

Template Studio is a Capture The Flag challenge that runs as a single privileged
Docker container. Inside it, an outer host runs its own Docker engine and deploys
a small Flask web application with Docker Compose. The application renders
personalized greeting cards, and it builds those cards from user input in a way
that lets you inject Jinja2 template expressions. The goal is to turn that
Server-Side Template Injection into code execution, move laterally through the
inner container, escalate to inner root, and finally break back out to the outer
host.

There are five flags:

| Flag file | Location | Prefix |
|---|---|---|
| flag.txt | web container, user `jinja` | `FLAG{...}` |
| flag.txt | web container, user `mako` | `FLAG{...}` |
| root.txt | web container, `root` | `TEMPLATE_FLAG{...}` |
| user.txt | outer host, user `webdev` | `MAIN_FLAG{...}` |
| root.txt | outer host, `root` | `MAIN_FLAG{...}` |

## Requirements

- Docker Engine that can run a privileged container (Docker Desktop works).
- Internet access on the first run: the inner stack pulls its base image
  (`python:3.12-slim`) and a static Docker client at build time.
- Works on both amd64 and arm64 hosts.

## Running the challenge

```bash
git clone https://github.com/jesse-quinn/CTF-4.git
cd CTF-4
docker image build -t ctf4:latest .
docker container run -it --rm --privileged \
  --hostname template-studio --name template-studio \
  -p 8080:8080 -p 22:22 -p 23:23 \
  ctf4:latest
```

Run the build and run from inside the cloned `CTF-4` directory. On Docker
Desktop (macOS, Windows) do not use `sudo`; on a Linux host, prefix both
commands with `sudo` or add your user to the `docker` group.

Then wait for the inner Docker Compose stack to finish deploying. The web
application is served on port 8080.

Note: if you use `-d`, you will not see the inner Compose deployment progress.

If some of those host ports are already in use on your machine, remap the left
side of each `-p` flag (for example `-p 18080:8080 -p 2222:22 -p 2323:23`); the
challenge itself is unaffected.

## Hosting model

Host the challenge as a running instance players connect to over the network;
do not distribute the built image. The outer deploy credential is materialized
at build time, so it is recoverable from the built image's `docker history` by
anyone handed the image, which is not a concern for a network-hosted instance.
Internet access is required only at first build (for the inner base image and
the static Docker client); once built, the challenge, including the final
socket-breakout step, runs with no outbound network.

## Rules

- Do not read the flag files or the solution notes during setup. The challenge
  is finding them through gameplay.
- The intended solution path is documented, for maintainers, in
  `docs/WALKTHROUGH.md`. It is a spoiler; do not open it if you want to play.

## Credits

This is an original challenge, inspired by the Himanshukr000/CTF-DOCKERS
collection (<https://github.com/Himanshukr000/CTF-DOCKERS>) and themed on the
web category, specifically Server-Side Template Injection in a Flask and Jinja2
application. See `CHANGELOG.md` for the release history.
