# Runtime configuration for the Template Studio app.
#
# The deploy account below is what the studio uses to push rendered cards to the
# staging box over SSH. Keeping a plaintext service credential next to the app
# is the reused-secret mistake: the same password is the mako login on this host.
LISTEN_PORT = 8080

DEPLOY_SSH_USER = "mako"
DEPLOY_SSH_PASSWORD = "Lpy6cWAdsi9WRcpEohd4uRR0"
