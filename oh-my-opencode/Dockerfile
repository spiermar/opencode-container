FROM opencode-base

USER opencode
COPY --chown=opencode:opencode oh-my-opencode.jsonc /home/opencode/.opencode/oh-my-opencode.jsonc
RUN . ~/.nvm/nvm.sh && npx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no --openai=no
