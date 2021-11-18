# Dockerfile to test DEBS packages

ARG GOLANG_VERSION=1.16
ARG DISTRO_NAME
ARG DISTRO_VERS

FROM ppc64le/$DISTRO_NAME:$DISTRO_VERS

ARG GOLANG_VERSION
ARG DISTRO_NAME
ARG DISTRO_VERS

ARG DOCKER_VERS
ARG CONTAINERD_VERS

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y tzdata

RUN apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    wget \
    software-properties-common \
    lsb-release\
    make\
    gcc\
    libc-dev\
    procps\
    iptables libdevmapper1.02.1 && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    url="https://download.docker.com/linux/${DISTRO_NAME}/dists/${DISTRO_VERS}/pool/stable/ppc64el"; \
    wget "${url}/containerd.io_${CONTAINERD_VERS}-1_ppc64el.deb"; \
    wget "${url}/docker-ce-cli_${DOCKER_VERS}~3-0~${DISTRO_NAME}-${DISTRO_VERS}_ppc64el.deb"; \
    wget "${url}/docker-ce-rootless-extras_${DOCKER_VERS}~3-0~${DISTRO_NAME}-${DISTRO_VERS}_ppc64el.deb"; \
    wget "${url}/docker-ce_${DOCKER_VERS}~3-0~${DISTRO_NAME}-${DISTRO_VERS}_ppc64el.deb"; \
    dpkg -i *.deb

##
#Docker in Docker inspired from
#  https://github.com/docker-library/docker/tree/master/20.10/dind
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
##
RUN set -eux; \
        addgroup --system dockremap; \
        adduser --system --ingroup dockremap dockremap; \
        echo 'dockremap:165536:65536' >> /etc/subuid; \
        echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 42b1175eda071c0e9121e1d64345928384a93df1
# ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377
ENV DOCKERD_COMMIT 8baa881aab85f8398d2edbbcc0da4bd1f556dd98
# ENV DOCKERD_COMMIT 094faa88f437cafef7aeb0cc36e75b59046cc4b9

COPY test_launch.sh /usr/local/bin/test_launch.sh

RUN set -eux; \
    wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
    wget -O /usr/local/bin/dockerd-entrypoint.sh "https://raw.githubusercontent.com/docker-library/docker/${DOCKERD_COMMIT}/20.10/dind/dockerd-entrypoint.sh"; \
    chmod +x /usr/local/bin/dind; \
    chmod +x /usr/local/bin/dockerd-entrypoint.sh; \
    chmod +x /usr/local/bin/test_launch.sh;

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["/usr/local/bin/test_launch.sh"]
CMD []
