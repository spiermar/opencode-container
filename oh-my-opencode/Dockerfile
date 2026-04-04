ARG OH_MY_OPENCODE_VERSION=3.15.0
ARG BASE_IMAGE=opencode-base
FROM ${BASE_IMAGE}
ARG OH_MY_OPENCODE_VERSION

USER opencode
COPY --chown=opencode:opencode oh-my-opencode.jsonc /home/opencode/.opencode/oh-my-opencode.jsonc
RUN . ~/.nvm/nvm.sh && npx --yes oh-my-opencode@"${OH_MY_OPENCODE_VERSION}" install --no-tui --claude=no --gemini=no --copilot=no --openai=no
