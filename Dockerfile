FROM quay.io/ctron/rust-esp-stage-3:develop

# set up the build directory
RUN mkdir /build
VOLUME /build
WORKDIR /build

COPY create-project image-project bindgen-project build-project xargo-project /usr/local/bin/
RUN chmod a+x /usr/local/bin/*
COPY templates /templates

CMD /usr/local/bin/build-project
