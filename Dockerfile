FROM debian:stable-slim

ARG GITHUB_RUNNER_VERSION="2.294.0"

ENV RUNNER_NAME "athena-runner"
ENV GITHUB_PAT ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        libssl-dev \
        python3 python3-venv python3-dev python3-pip \
    && pip3 install --upgrade databricks-cli \
    && apt-get clean \
    && pip3 cache purge \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


USER github
WORKDIR /home/github
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

### This hack needed because twistlock scan requires newest version of oauthlib than azure have due security issues
RUN sudo pip3 install --upgrade --target=/opt/az/lib/python3.10 oauthlib && sudo rm -rf /opt/az/lib/python3.10/test

RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh
RUN rm -rf /home/github/externals/node12/lib/node_modules/npm && \
    rm -rf /home/github/externals/node16/lib/node_modules/npm && \
    rm /home/github/externals/node12/bin/npm && \
    rm /home/github/externals/node16/bin/npm

COPY --chown=github:github ./.scalafmt.conf ./usr/local/bin/.scalafmt.conf
RUN VERSION=3.4.3 && \
    INSTALL_LOCATION=/usr/local/bin/scalafmt-native && \
    curl https://raw.githubusercontent.com/scalameta/scalafmt/master/bin/install-scalafmt-native.sh | \
    sudo bash -s -- $VERSION $INSTALL_LOCATION

ENTRYPOINT ["/usr/local/bin/scalafmt-native", "-v"]
