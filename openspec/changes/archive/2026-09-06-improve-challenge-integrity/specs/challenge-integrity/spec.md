# Challenge Integrity

## ADDED Requirements

### Requirement: Offline-reproducible climax

The socket-breakout step and any solve-time action SHALL reuse a container image
already present in the outer engine from the inner build, rather than pulling a
new image that requires network access at solve time.

#### Scenario: Breakout on a network-isolated host

- **WHEN** a player follows the documented final breakout after the challenge
  has finished building, on a host with no outbound internet access
- **THEN** the `docker run -v /:/host ...` command uses an image the outer
  engine already holds from the inner build (`python:3.12-slim-bookworm`) and
  reads the outer flag without pulling `alpine` or any other new image

### Requirement: Robust service startup

Service startup SHALL be resilient: the primary web service SHALL NOT be coupled
to `sshd` init success.

#### Scenario: sshd fails to start inside the web container

- **WHEN** the inner `sshd` fails to start or errors during container startup
- **THEN** the Flask web application still starts and serves on port 8080, and
  `start.sh` does not abort the web entry point because of the `sshd` outcome

### Requirement: Staged inner build tree is protected on the outer host

Inner-stack secrets, keys, and flag values staged under the outer host SHALL NOT
be readable by the unprivileged outer account.

#### Scenario: Outer webdev reads the staged inner tree

- **WHEN** the unprivileged outer `webdev` account reads files under
  `/opt/studio` on the outer host
- **THEN** the inner flag plaintext and the reused `mako` credential are not
  world-readable, so the intended SSTI-to-RCE chain cannot be bypassed by a
  direct file read

### Requirement: Reproducible build pins

Base images, language packages, and any fetched static binary the documented
exploit depends on SHALL be pinned so the challenge builds reproducibly and the
documented gadget keeps resolving.

#### Scenario: Rebuild after an upstream release

- **WHEN** the inner web image is rebuilt after a new Flask or Jinja2 release
- **THEN** the build installs the pinned `flask` and `jinja2` versions, and the
  documented `cycler.__init__.__globals__.os` SSTI payload still resolves

### Requirement: Walkthrough honesty about the socket primitive

Where a mounted `docker.sock` yields outer root directly, the WALKTHROUGH SHALL
state that plainly and SHALL NOT claim a downstream credential or SSH stage is
required when it is a realism flourish, and SHALL record any residual left in
the built image.

#### Scenario: Maintainer reads the notes section

- **WHEN** a maintainer reads the WALKTHROUGH "Notes and red herrings" section
- **THEN** it states that the mounted `docker.sock` reads the outer user flag
  directly, that the SSH-as-`webdev` step is a realism flourish rather than
  load-bearing, and that the deploy password is embedded in image build history
  with a network-only hosting model recommended in the README
