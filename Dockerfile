FROM alpine:3.7 AS wget
RUN apk add --no-cache ca-certificates wget tar

FROM alpine:3.7 AS pip
RUN apk add --no-cache py-pip

FROM wget AS docker
ARG DOCKER_VERSION=17.05.0-ce
RUN wget -qO- https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz | \
    tar -xvz --strip-components=1 -C /bin

FROM pip AS aws
ARG AWS_VERSION=1.14.17
RUN pip install awscli==${AWS_VERSION}
RUN apk del py-pip

FROM wget AS terraform
ARG TERRAFORM_VERSION=0.11.1
RUN wget -qO- https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform.zip && \
    unzip -d /bin terraform.zip

FROM wget AS packer
ARG PACKER_VERSION=1.1.3
RUN wget -qO- https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip > packer.zip && \
    unzip -d /bin packer.zip

FROM mhart/alpine-node:9.3.0
LABEL maintainer="steve@revl.ca" \
      version="0.0.1"
ENV PYTHON_VERSION 2.7
ENV PYTHON_PATH /usr/lib/python${PYTHON_VERSION}/site-packages
COPY --from=aws ${PYTHON_PATH} ${PYTHON_PATH}
COPY --from=aws /usr/bin/aws /bin
COPY --from=docker /bin/docker /bin
COPY --from=terraform /bin/terraform /bin
COPY --from=packer /bin/packer /bin
RUN apk add --no-cache python
