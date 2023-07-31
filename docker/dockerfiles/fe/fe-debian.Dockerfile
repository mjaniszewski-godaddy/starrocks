# This docker file build the Starrocks fe ubuntu image
# Please run this command from the git repo root directory to build:
#   - Use artifact image to package runtime container:
#     > DOCKER_BUILDKIT=1 docker build --build-arg ARTIFACT_SOURCE=image --build-arg ARTIFACTIMAGE=ghcr.io/starrocks/starrocks/artifact-ubuntu:latest -f docker/dockerfiles/fe/fe-ubuntu.Dockerfile -t fe-ubuntu:latest .
#   - Use locally build artifacts to package runtime container:
#     > DOCKER_BUILDKIT=1 docker build --build-arg ARTIFACT_SOURCE=local --build-arg LOCAL_REPO_PATH=. -f docker/dockerfiles/fe/fe-ubuntu.Dockerfile -t fe-ubuntu:latest .
#
# The artifact source used for packing the runtime docker image
#   image: copy the artifacts from a artifact docker image.
#   local: copy the artifacts from a local repo. Mainly used for local development and test.
ARG ARTIFACT_SOURCE=image

ARG ARTIFACTIMAGE=artifact:latest
FROM ${ARTIFACTIMAGE} as artifacts-from-image

# create a docker build stage that copy locally build artifacts
FROM busybox:latest as artifacts-from-local
ARG LOCAL_REPO_PATH
COPY ${LOCAL_REPO_PATH}/output/fe /release/fe_artifacts/fe


FROM artifacts-from-${ARTIFACT_SOURCE} as artifacts


FROM 764525110978.dkr.ecr.us-west-2.amazonaws.com/debian:11.7
ARG STARROCKS_ROOT=/opt/starrocks

RUN apt-get update -y && apt-get install -y --no-install-recommends \
        default-jdk mysql-client curl vim tree net-tools less tzdata linux-perf && \
        ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
        dpkg-reconfigure -f noninteractive tzdata
RUN echo "export PATH=/usr/lib/linux-tools/5.15.0-60-generic:$PATH" >> /etc/bash.bashrc
ENV JAVA_HOME=/lib/jvm/default-java

WORKDIR $STARROCKS_ROOT

# Copy all artifacts to the runtime container image
COPY --from=artifacts /release/fe_artifacts/ $STARROCKS_ROOT/

# Copy fe k8s scripts to the runtime container image
COPY docker/dockerfiles/fe/*.sh $STARROCKS_ROOT/

# Create directory for FE metadata
RUN touch /.dockerenv && mkdir -p /opt/starrocks/fe/meta
