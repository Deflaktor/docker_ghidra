FROM openjdk:16-jdk-alpine3.12

ENV DEBIAN_FRONTEND=noninteractive

ENV GHIDRA_REPOS_PATH /srv/repositories
ENV GHIDRA_INSTALL_PATH /opt
ENV GHIDRA_RELEASE_URL https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.1.2_build/ghidra_10.1.2_PUBLIC_20220125.zip
ENV GHIDRA_VERSION 10.1.2_PUBLIC
ENV GHIDRA_SHA_256 ac96fbdde7f754e0eb9ed51db020e77208cdb12cf58c08657a2ab87cb2694940

# Create ghidra user.
RUN addgroup -S ghidra && \
    adduser -D -S ghidra -G ghidra

RUN apk add --update --no-cache \
    wget \
    unzip \
    bash

# Get Ghidra.
WORKDIR ${GHIDRA_INSTALL_PATH}
RUN wget --progress=bar:force -O ghidra_${GHIDRA_VERSION}.zip ${GHIDRA_RELEASE_URL} && \
    echo "${GHIDRA_SHA_256}  ghidra_${GHIDRA_VERSION}.zip" | sha256sum -c && \
    unzip ghidra_${GHIDRA_VERSION}.zip && \
    mv ghidra_${GHIDRA_VERSION} ghidra && \
    rm ghidra_${GHIDRA_VERSION}.zip && \
    chown -R ghidra: ${GHIDRA_INSTALL_PATH}/ghidra

# Install Ghidra server.
RUN cd ${GHIDRA_INSTALL_PATH}/ghidra/server && \
    mkdir -p ${GHIDRA_REPOS_PATH} && \
    sed 's|ghidra.repositories.dir=.*|ghidra.repositories.dir='"${GHIDRA_REPOS_PATH}"'|' server.conf > ${GHIDRA_REPOS_PATH}/server.conf && \
    sed 's|JAVA_HOME=|# JAVA_HOME=|' ${GHIDRA_INSTALL_PATH}/ghidra/server/ghidraSvr > ${GHIDRA_INSTALL_PATH}/ghidra/server/ghidraSvr && \
    sed 's|JAVA_HOME=|# JAVA_HOME=|' ${GHIDRA_INSTALL_PATH}/ghidra/support/launch.sh > ${GHIDRA_INSTALL_PATH}/ghidra/support/launch.sh && \
    rm server.conf && \
    ln -s ${GHIDRA_REPOS_PATH}/server.conf server.conf && \
    ${GHIDRA_INSTALL_PATH}/ghidra/server/svrInstall && \
    chown -R ghidra: ${GHIDRA_REPOS_PATH} && \
    cd /home/ghidra && \
    ln -s ${GHIDRA_INSTALL_PATH}/ghidra/server/svrAdmin svrAdmin && \
    ln -s ${GHIDRA_INSTALL_PATH}/ghidra/server/server.conf server.conf && \
    ln -s ${GHIDRA_INSTALL_PATH}/ghidra/server/svrInstall svrInstall && \
    ln -s ${GHIDRA_INSTALL_PATH}/ghidra/server/svrUninstall svrUninstall && \
    ln -s ${GHIDRA_INSTALL_PATH}/ghidra/server/ghidraSvr ghidraSvr 

VOLUME ${GHIDRA_REPOS_PATH}

# Setup user environment.
USER ghidra
WORKDIR /home/ghidra
ENV HOME /home/ghidra

COPY server.conf ${GHIDRA_INSTALL_PATH}/ghidra/server/server.conf

# Ghidra's default ports.
EXPOSE 13100
EXPOSE 13101
EXPOSE 13102

ENTRYPOINT ${GHIDRA_INSTALL_PATH}/ghidra/server/ghidraSvr console
