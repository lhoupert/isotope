####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

RUN update-ca-certificates

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


WORKDIR /isotope

COPY ./ .

# We no longer need to use the x86_64-unknown-linux-musl target
RUN cargo build --release


####################################################################################################
## Copy last version of libc library for amd64 and arm64 archs
####################################################################################################
FROM --platform=amd64 gcr.io/distroless/cc AS final-amd64
COPY --from=builder /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6

FROM --platform=arm64 gcr.io/distroless/cc AS final-arm64
COPY --from=builder /lib/aarch64-linux-gnu/libc.so.6 /lib/aarch64-linux-gnu/libc.so.6

####################################################################################################
## Final image
####################################################################################################
FROM final-${TARGETARCH}

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /isotope

# Copy our build
COPY --from=builder /isotope/target/release/isotope ./

# Use an unprivileged user.
USER isotope_user:isotope_user

CMD ["/isotope/isotope"]
