# =============================================================================
# jenkins-cicd/agent/Dockerfile — Custom Jenkins SSH Agent
#
# Base: jenkins/ssh-agent (Debian Bookworm, SSH server pre-configured)
#   - Accepts SSH connections from Jenkins master
#   - JENKINS_AGENT_SSH_PUBKEY env var → /home/jenkins/.ssh/authorized_keys
#
# Added:
#   - python3, python3-pip  — for running Django tests (manage.py test)
#   - git                   — for checkout stage
#   - openssh-client        — for SSH deploy to pyforum-docker-host
# =============================================================================

FROM jenkins/ssh-agent:latest

USER root

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    openssh-client \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# NOTE: Do NOT add USER jenkins here.
# The base jenkins/ssh-agent entrypoint (setup-sshd) must run as root
# to start sshd on port 22. sshd itself handles privilege drop for sessions.
