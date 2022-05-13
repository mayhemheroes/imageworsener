# Build Stage
FROM aflplusplus/aflplusplus as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git make libpng-dev libjpeg-dev libwebp-dev

## Add source code to the build stage.
WORKDIR /
RUN git clone https://github.com/capuanob/imageworsener.git
WORKDIR /imageworsener
RUN git checkout mayhem

## Build
RUN AFL_INSTRUMENT=1 make -C scripts

# Package Stage
FROM aflplusplus/aflplusplus
COPY --from=builder /imageworsener/tests/srcimg /corpus
COPY --from=builder /imageworsener/imagew /
ENTRYPOINT ["afl-fuzz", "-i", "/corpus", "-o", "/out"]
CMD ["/imagew", "-w", "5", "-h", "5", "@@", "-", "-outfmt", "png"]
