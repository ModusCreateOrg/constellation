FROM golang:alpine
MAINTAINER "Modus Create DevOps Team <devops@moduscreate.com>"

ENV TERRAFORM_VERSION=0.11.11

RUN apk add --update git bash openssh

ENV TF_DEV=true
ENV TF_RELEASE=true

WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ && \
    git checkout v${TERRAFORM_VERSION} && \
    /bin/bash scripts/build.sh
    
RUN apk add curl && \
    curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator && \
    chmod 755 /usr/local/bin/aws-iam-authenticator && \
    curl -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl && \
    chmod 755 /usr/local/bin/kubectl

WORKDIR $GOPATH
ENTRYPOINT ["terraform"]