FROM alpine:3.10 as builder

ARG SHARDS_VERSION="0.8.1"

RUN apk update
RUN apk add curl yaml-dev git build-base libressl-dev zlib-dev libxml2-dev

# Add crystal from edge
RUN apk add crystal=0.30.1-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

RUN crystal --version

# Compile shards
RUN curl -L https://github.com/crystal-lang/shards/archive/v${SHARDS_VERSION}.tar.gz | tar -xz
RUN CRFLAGS=--release make -C ./shards-${SHARDS_VERSION}

# Install shards for caching
COPY shard.yml shard.yml
RUN ./shards-${SHARDS_VERSION}/bin/shards install --production

# Manually remake libscrypt, PostInstall fails inexplicably
RUN make -C ./lib/scrypt/ clean
RUN make -C ./lib/scrypt/

# Add src
COPY . ./

# Build application
RUN crystal build src/engine-api.cr --release --no-debug --static

# Build a minimal docker image
FROM alpine:3.10
COPY --from=builder engine-api engine-api

# Run the app binding on port 3000
EXPOSE 3000
HEALTHCHECK CMD wget --spider localhost:3000/
CMD ["/engine-api", "-b", "0.0.0.0", "-p", "3000"]

