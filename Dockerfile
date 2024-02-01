####################################################################################################
## Builder
####################################################################################################
FROM --platform=$BUILDPLATFORM rust:latest AS rust-builder

RUN rustup target add \
    x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
RUN rustup toolchain install --force-non-host \
    stable-x86_64-unknown-linux-gnu stable-aarch64-unknown-linux-gnu
RUN rustup component add rustfmt
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc \
    CC_x86_64_unknown_linux_gnu=x86_64-linux-gnu-gcc \
    CXX_x86_64_unknown_linux_gnu=x86_64-linux-gnu-g++ \
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
    CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc \
    CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++ \
    CARGO_INCREMENTAL=0

# : toolchain 'stable-x86_64-unknown-linux-gnu' may not be able to run on this system.
#  => => # warning: If you meant to build software to target that platform, perhaps try `rustup target add x86_64-unknown-linux-gnu` instead?
#  => => # info: syncing channel updates for 'stable-x86_64-unknown-linux-

# amd64 build ----------------------------
FROM --platform=$BUILDPLATFORM rust-builder AS build-amd64
WORKDIR /isotope
COPY . .
RUN cargo install --target x86_64-unknown-linux-gnu --path .
RUN mv ./target/x86_64-unknown-linux-gnu/release/isotope /usr/bin/isotope
 
# arm64 build ----------------------------
FROM --platform=$BUILDPLATFORM rust-builder AS build-arm64
WORKDIR /isotope
COPY . .
RUN cargo install --target aarch64-unknown-linux-gnu --path .
RUN mv ./target/aarch64-unknown-linux-gnu/release/isotope /usr/bin/isotope

# Final arch images ----------------------
 
# FROM --platform=amd64 gcr.io/distroless/cc AS final-amd64
FROM --platform=amd64 debian:bullseye AS final-amd64
COPY --from=build-amd64 /usr/bin/isotope /usr/bin/isotope
COPY --from=build-amd64 /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6

# FROM --platform=arm64 gcr.io/distroless/cc AS final-arm64
FROM --platform=arm64 debian:bullseye AS final-arm64
COPY --from=build-arm64 /usr/bin/isotope /usr/bin/isotope
COPY --from=build-arm64  /lib/aarch64-linux-gnu/libc.so.6 /lib/aarch64-linux-gnu/libc.so.6
 

####################################################################################################
## Final image
####################################################################################################
FROM final-${TARGETARCH}

ENV USER=isotope_user
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"


# Use an unprivileged user.
USER isotope_user:isotope_user

CMD ["/usr/bin/isotope/isotope"]
