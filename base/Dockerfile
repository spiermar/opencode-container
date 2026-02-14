FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# 1. System packages + GitHub CLI repository
RUN apt-get update && apt-get install -y \
    build-essential git curl jq make vim ca-certificates gnupg sudo postgresql-client wget zip unzip gnupg openssh-client ripgrep \
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

# 5. Playwright system dependencies and browser (as root, using opencode's node)
USER root
RUN bash -c 'export NVM_DIR="/home/opencode/.nvm" && . "$NVM_DIR/nvm.sh" && npx playwright install chromium --with-deps'

# 6. Fix cache ownership (root's npx created root-owned files)
RUN chown -R opencode:opencode /home/opencode/.npm /home/opencode/.cache

# 7. Switch back to opencode user for remaining setup
USER opencode

# 8. Add GitHub to known_hosts for non-interactive git operations
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# 9. Install OpenCode CLI
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@latest

# 10. Install Anthropic Agent Skills
# NOTE: Some skills (docx, pdf, pptx, xlsx) are source-available, not Apache 2.0.
#       See https://github.com/anthropics/skills for licensing details.
RUN git clone https://github.com/anthropics/skills.git ~/.config/opencode/anthropics-skills \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/anthropics-skills/skills \
             ~/.config/opencode/skills/anthropics

# 11. Install spiermar skills and agents
RUN git clone https://github.com/spiermar/oh-no-claudecode.git ~/.config/opencode/oh-no-claudecode \
    && mkdir -p ~/.config/opencode/skills ~/.config/opencode/agents \
    && ln -s ~/.config/opencode/oh-no-claudecode/skills \
             ~/.config/opencode/skills/spiermar \
    && ln -s ~/.config/opencode/oh-no-claudecode/agents \
             ~/.config/opencode/agents/spiermar

# 12. Install Vercel Labs skills
RUN git clone https://github.com/vercel-labs/skills.git ~/.config/opencode/vercel-labs-skills \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/vercel-labs-skills/skills \
             ~/.config/opencode/skills/vercel-labs

# 13. Copy provider configuration
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# 14. Copy entrypoint
COPY --chown=opencode:opencode entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Environment defaults
ENV CLI_PORT=9898
ENV MODE=server

WORKDIR /home/opencode/workspace
EXPOSE 9898

ENTRYPOINT ["/home/opencode/entrypoint.sh"]
