FROM opencode-base

USER opencode

# Using @latest because get-shit-done-cc is a CLI tool that should always use the newest version
RUN . ~/.nvm/nvm.sh && CLAUDE_CONFIG_DIR=/home/opencode/.config/opencode npx get-shit-done-cc@latest --opencode --global