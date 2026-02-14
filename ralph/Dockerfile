FROM opencode-base

USER opencode
RUN git clone https://github.com/snarktank/ralph.git ~/.config/opencode/ralph \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/ralph/skills \
             ~/.config/opencode/skills/ralph
