FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# 1. System packages + GitHub CLI repository
RUN apt-get update && apt-get install -y \
    git curl vim ca-certificates gnupg sudo \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 2. Create non-root user with uid/gid 1000
#    Remove any existing user/group with uid/gid 1000 first (ubuntu image may have 'ubuntu' user)
RUN (getent passwd 1000 | cut -d: -f1 | xargs -r userdel -r 2>/dev/null || true) \
    && (getent group 1000 | cut -d: -f1 | xargs -r groupdel 2>/dev/null || true) \
    && groupadd -g 1000 opencode \
    && useradd -u 1000 -g 1000 -m -s /bin/bash opencode \
    && mkdir -p /home/opencode/workspace \
    && chown opencode:opencode /home/opencode/workspace

# 3. Switch to opencode user for nvm setup
USER opencode
WORKDIR /home/opencode
ENV HOME=/home/opencode

# 4. Install nvm + Node.js LTS
ENV NVM_DIR=/home/opencode/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# 5. Playwright system dependencies (as root, using opencode's node)
USER root
RUN bash -c 'export NVM_DIR="/home/opencode/.nvm" && . "$NVM_DIR/nvm.sh" && npx playwright install-deps'

# 6. Fix npm cache ownership (root's npx created root-owned files)
RUN chown -R opencode:opencode /home/opencode/.npm

# 7. Switch back to opencode user for remaining setup
USER opencode

# 8. Install OpenCode CLI
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@latest

# 9. Install Superpowers
RUN git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers \
    && mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js \
             ~/.config/opencode/plugins/superpowers.js \
    && ln -s ~/.config/opencode/superpowers/skills \
             ~/.config/opencode/skills/superpowers

# 10. Copy provider configuration
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# 11. Copy entrypoint
COPY --chown=opencode:opencode entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Environment defaults
ENV PORT=9898
ENV MODE=server

WORKDIR /home/opencode/workspace
EXPOSE 9898

ENTRYPOINT ["/home/opencode/entrypoint.sh"]
