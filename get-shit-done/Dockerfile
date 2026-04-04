ARG GET_SHIT_DONE_CC_VERSION=1.32.0
ARG BASE_IMAGE=opencode-base
FROM ${BASE_IMAGE}
ARG GET_SHIT_DONE_CC_VERSION

USER opencode

RUN . ~/.nvm/nvm.sh && CLAUDE_CONFIG_DIR=/home/opencode/.config/opencode npx --yes get-shit-done-cc@"${GET_SHIT_DONE_CC_VERSION}" --opencode --global
