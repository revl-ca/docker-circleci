FROM alpine:3.7@sha256:e1871801d30885a610511c867de0d6baca7ed4e6a2573d506bbec7fd3b03873f AS alpine
FROM golang:alpine@sha256:0cd3f4746c8c592c3f0635b0122ea3cc0d54f0aa64e35853c8344fcbb2a59de7 AS golang

FROM alpine AS wget
RUN apk add --no-cache ca-certificates wget tar

FROM alpine AS pip
RUN apk add --no-cache py-pip

FROM wget AS docker
ARG DOCKER_VERSION=17.05.0-ce
RUN wget -qO- https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz | \
    tar -xvz --strip-components=1 -C /bin

FROM pip AS aws
ARG AWS_VERSION=1.14.17
RUN pip install awscli==${AWS_VERSION} && \
    apk del py-pip

FROM wget AS terraform
ARG TERRAFORM_VERSION=0.11.1
RUN wget -qO- https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform.zip && \
    unzip -d /bin terraform.zip

FROM wget AS packer
ARG PACKER_VERSION=1.1.3
RUN wget -qO- https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip > packer.zip && \
    unzip -d /bin packer.zip

FROM golang AS terratest
RUN apk add --no-cache git && \
    go get github.com/gruntwork-io/terratest/modules/terraform

FROM pip AS ansible
ARG ANSIBLE_VERSION=2.6.2
RUN apk --update add python py-pip openssl ca-certificates && \
    apk --update add --virtual build-dependencies python-dev libffi-dev openssl-dev build-base  && \
    pip install --upgrade pip cffi && \
    pip install ansible==${ANSIBLE_VERSION} pycrypto

FROM mhart/alpine-node:9.3.0@sha256:fdb977910e73b209a3acdafbb65304128818773d436701ec35b24da4929fb1b6
LABEL org.label-schema.description="" \
      org.label-schema.name="Docker CircleCI" \
      org.label-schema.schema-version="1.0.0-rc.1" \
      org.label-schema.vcs-url="https://github.com/revl-ca/docker-circleci" \
      org.label-schema.vendor="REVL" \
      org.label-schema.version="0.0.1"
ENV PYTHON_VERSION=2.7
ENV PYTHON_PATH=/usr/lib/python${PYTHON_VERSION}/site-packages
ENV GOROOT=/usr/lib/go \
    GOPATH=/gopath \
    GOBIN=/gopath/bin \
    PATH=$PATH:$GOROOT/bin:$GOPATH/bin
RUN apk add --no-cache git python sshpass openssh-client rsync curl 'go=1.9.4-r0'
COPY --from=aws ${PYTHON_PATH} ${PYTHON_PATH}
COPY --from=ansible ${PYTHON_PATH} ${PYTHON_PATH}
COPY --from=ansible /usr/bin/ansible* /bin/
COPY --from=aws /usr/bin/aws /bin
COPY --from=docker /bin/docker /bin
COPY --from=terraform /bin/terraform /bin
COPY --from=packer /bin/packer /bin
COPY --from=terratest /go /go
