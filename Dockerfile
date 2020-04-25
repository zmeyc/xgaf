FROM swift:5.2.2-bionic as builder

WORKDIR /app
COPY Package.swift ./
COPY Tests/ ./Tests
COPY Sources/ ./Sources

RUN swift build -c release


FROM swift:5.2.2-bionic

COPY --from=builder /app/.build/release/xgaf /usr/local/bin/
COPY --from=builder /usr/lib/swift/ /usr/lib/swift/

CMD ["xgaf"]

