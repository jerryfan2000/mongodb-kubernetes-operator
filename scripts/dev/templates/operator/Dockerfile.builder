ARG builder_image
FROM almalinux/9-minimal AS builder

RUN mkdir /workspace
WORKDIR /workspace

COPY . .

ARG TARGETOS
ARG TARGETARCH

# Set environment variables
ENV GO_VERSION=1.23.1
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Install dependencies
RUN microdnf -y update && \
    microdnf -y install wget tar gzip dos2unix && \
    microdnf clean all

# Download and install Go
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Build manager
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager cmd/manager/main.go \
  && dos2unix /workspace/build/bin/user_setup

FROM almalinux/9-minimal

ENV OPERATOR=manager \
    USER_UID=2000 \
    USER_NAME=mongodb-kubernetes-operator

RUN mkdir /workspace
COPY --from=builder /workspace/manager /workspace/
COPY --from=builder /workspace/build/bin /usr/local/bin

RUN  /usr/local/bin/user_setup
USER ${USER_UID}
ENTRYPOINT ["/usr/local/bin/entrypoint"]
