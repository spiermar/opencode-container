ARG BASE_IMAGE=opencode-base
FROM ${BASE_IMAGE}

USER opencode
RUN git clone https://github.com/snarktank/ralph.git ~/.config/opencode/ralph \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/ralph/skills \
             ~/.config/opencode/skills/ralph
