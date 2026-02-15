# 1. Build the base image
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# 1.1 System packages + GitHub CLI repository
RUN apt-get update && apt-get install -y \
    build-essential git curl jq make vim ca-certificates gnupg sudo postgresql-client wget zip unzip gnupg openssh-client ripgrep shellcheck \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 \
    && chmod +x /usr/local/bin/hadolint

# 1.2 Create non-root user with uid/gid 1000
RUN (getent passwd 1000 | cut -d: -f1 | xargs -r userdel -r 2>/dev/null || true) \
    && (getent group 1000 | cut -d: -f1 | xargs -r groupdel 2>/dev/null || true) \
    && groupadd -g 1000 opencode \
    && useradd -u 1000 -g 1000 -m -s /bin/bash opencode \
    && mkdir -p /home/opencode/workspace \
    && chown opencode:opencode /home/opencode/workspace

# 1.3 Switch to opencode user for nvm setup
USER opencode
WORKDIR /home/opencode
ENV HOME=/home/opencode

# 1.4 Install nvm + Node.js LTS
ENV NVM_DIR=/home/opencode/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# 1.5 Playwright system dependencies and browser (as root, using opencode's node)
USER root
RUN bash -c 'export NVM_DIR="/home/opencode/.nvm" && . "$NVM_DIR/nvm.sh" && npx playwright install chromium --with-deps'

# 1.6 Fix cache ownership (root's npx created root-owned files)
RUN chown -R opencode:opencode /home/opencode/.npm /home/opencode/.cache

# 1.7 Switch back to opencode user for remaining setup
USER opencode

# 1.8 Add GitHub to known_hosts for non-interactive git operations
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# 1.9 Install OpenCode CLI and TypeScript
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@1.2.1 typescript@5.9.3

# 1.10 Install Anthropic Agent Skills
RUN git clone https://github.com/anthropics/skills.git ~/.config/opencode/anthropics-skills \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/anthropics-skills/skills \
             ~/.config/opencode/skills/anthropics

# 1.11 Install spiermar skills and agents
RUN git clone https://github.com/spiermar/oh-no-claudecode.git ~/.config/opencode/oh-no-claudecode \
    && mkdir -p ~/.config/opencode/skills ~/.config/opencode/agents \
    && ln -s ~/.config/opencode/oh-no-claudecode/skills \
             ~/.config/opencode/skills/spiermar \
    && ln -s ~/.config/opencode/oh-no-claudecode/agents \
             ~/.config/opencode/agents/spiermar

# 1.12 Install Vercel Labs skills
RUN git clone https://github.com/vercel-labs/skills.git ~/.config/opencode/vercel-labs-skills \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/vercel-labs-skills/skills \
             ~/.config/opencode/skills/vercel-labs

# 1.13 Install Superpowers
RUN git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers \
    && mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js \
             ~/.config/opencode/plugins/superpowers.js \
    && ln -s ~/.config/opencode/superpowers/skills \
             ~/.config/opencode/skills/superpowers

# 1.14 Copy provider configuration
COPY --chown=opencode:opencode base/opencode.json /home/opencode/.config/opencode/opencode.json

# 1.15 Copy entrypoint
COPY --chown=opencode:opencode base/entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# 1.16 Copy opencode.json to workspace for MCP config
COPY --chown=opencode:opencode base/opencode.json /home/opencode/workspace/opencode.json

# Environment defaults
ENV CLI_PORT=9898
ENV MODE=server

WORKDIR /home/opencode/workspace
EXPOSE 9898

ENTRYPOINT ["/home/opencode/entrypoint.sh"]