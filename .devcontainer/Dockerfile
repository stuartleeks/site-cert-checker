# Find the Dockerfile for mcr.microsoft.com/azure-functions/node at the following URLs:
# Node 10: https://github.com/Azure/azure-functions-docker/blob/dev/host/3.0/buster/amd64/node/node10/node10-core-tools.Dockerfile
# Node 12: https://github.com/Azure/azure-functions-docker/blob/dev/host/3.0/buster/amd64/node/node12/node12-core-tools.Dockerfile
ARG VARIANT=12
FROM mcr.microsoft.com/azure-functions/node:3.0-node${VARIANT}-core-tools

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

ARG USERNAME=node
USER $USERNAME
RUN mkdir -p ~/.local/bin
ENV PATH /home/${USERNAME}/.local/bin:$PATH

# Save command line history
RUN echo "export HISTFILE=/home/$USERNAME/commandhistory/.bash_history" >> "/home/$USERNAME/.bashrc" \
    && echo "export PROMPT_COMMAND='history -a'" >> "/home/$USERNAME/.bashrc" \
    && mkdir -p /home/$USERNAME/commandhistory \
    && touch /home/$USERNAME/commandhistory/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/commandhistory


# azure-cli
COPY scripts/azure-cli.sh /tmp/
RUN /tmp/azure-cli.sh

# bicep
COPY scripts/bicep.sh /tmp/
RUN /tmp/bicep.sh

RUN sudo apt-get -y install figlet

# azbrowse
COPY scripts/azbrowse.sh /tmp/
RUN /tmp/azbrowse.sh
