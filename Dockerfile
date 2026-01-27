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

# 2. Create non-root user
RUN useradd -m -s /bin/bash opencode \
    && mkdir -p /workspace \
    && chown opencode:opencode /workspace

# 3. Playwright system dependencies (as root)
RUN npx playwright install-deps

# 4. Switch to opencode user for remaining setup
USER opencode
WORKDIR /home/opencode

# 5. Install nvm + Node.js LTS
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# 6. Install OpenCode CLI
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@latest

# 7. Install Superpowers
RUN git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers \
    && mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js \
             ~/.config/opencode/plugins/superpowers.js \
    && ln -s ~/.config/opencode/superpowers/skills \
             ~/.config/opencode/skills/superpowers

# 8. Copy provider configuration
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# 9. Copy entrypoint
COPY --chown=opencode:opencode entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Environment defaults
ENV PORT=9898
ENV MODE=server

WORKDIR /workspace
EXPOSE 9898

ENTRYPOINT ["/home/opencode/entrypoint.sh"]
