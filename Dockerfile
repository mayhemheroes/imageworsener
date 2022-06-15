# Build Stage
FROM fuzzers/aflplusplus:3.12c as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y make libpng-dev libjpeg-dev libwebp-dev

## Add source code to the build stage.
WORKDIR /
ADD . /imageworsener
WORKDIR /imageworsener

## Build
RUN AFL_INSTRUMENT=1 make -C scripts -j$(nproc)

## Prepare all library dependencies for copy
RUN mkdir /deps
RUN cp `ldd ./imagew | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :
RUN cp `ldd /usr/local/bin/afl-fuzz | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :

# Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /usr/local/bin/afl-fuzz /afl-fuzz
COPY --from=builder /imageworsener/tests/srcimg /testsuite
COPY --from=builder /deps /usr/lib
COPY --from=builder /imageworsener/imagew /

env AFL_SKIP_CPUFREQ=1

ENTRYPOINT ["/afl-fuzz", "-i", "/testsuite", "-o", "/out"]
CMD ["/imagew", "-w", "5", "-h", "5", "@@", "-", "-outfmt", "png"]
