# Rust ESP compiler container [![Docker Repository on Quay](https://quay.io/repository/ctron/rust-esp/status "Docker Repository on Quay")](https://quay.io/repository/ctron/rust-esp)

This is a container which can be used to build a Rust project for the ESP32.

## Pre-requisites

  * Docker
  * A rust project (e.g. use [ctron/rust-esp-template](https://github.com/ctron/rust-esp-template) as example)

## Usage

This container image provides a few tools which can be run like this:

    docker run -ti -v $PWD:/home/project:z quay.io/ctron/rust-esp:latest

### Volume mapping

The `-v $PWD:/home/project:z` will map the current directory into the location
`/home/project` inside the container. This is required so that the tools inside
the container can work with the project.

The `$PWD` part uses the current directory. This will only work in a Bourne like shell. You can replace
this with the absolute path to your project instead.

You can drop the `:z` suffix, if you don't have SElinux on the host system.

All following example assue that you use `$PWD:/home/project:z`.

### Default command

This will run the default command `build-project`. You can run other commands, e.g. `bash` like this:

    docker run -ti -v $PWD:/home/project:z quay.io/ctron/rust-esp:latest bash

### Labels

The `master` branch of this repository will build into the `latest` label, which is also the default
if you omit the `:latest` suffix in the container name.

Each git tag will also be build into a container image tag, so e.g. git tag `0.0.1`, will be built into
the container tag `:0.0.1`.

So should the `latest` image break, it should always be possible to switch to a previous version.

## Bootstrapping

Initially a few files need to be set up. The ESP-IDF components need to be configured and compiled.
Run the following command to create an initial setup:

    docker run -ti -v $PWD:/home/project:z quay.io/ctron/rust-esp:latest create-project

This will create (overwrite) as few files which are required to build the project.
Next run:

    docker run -ti -v $PWD:/home/project:z quay.io/ctron/rust-esp:latest make menuconfig

Which will start the ESP-IDF build and shows you the menu config tool for configuring
your ESP project. Be sure to save when you exit.

## Building

In order to build the project, run the following command:

    docker run -ti -v $PWD:/home/project:z quay.io/ctron/rust-esp:latest

This will compile the ESP-IDF part, the rust part and finally convert it to an image
which you can upload to your ESP.

## Uploading

You can then upload the image using the `flash-project` executable:

    docker run -ti --device=/dev/ttyUSB0 -v $PWD:/home/project:z rust-esp32:latest flash-project

If this doesn't work or you need to use differnt tool it might be easier to
upload the image via `esptool` from the host machine. To do this call:

    esptool write_flash 0x10000 esp-app.bin

## Building the container

You can also build the container image yourself, by cloning this repository and executing:

    docker build . -t rust-esp

## Notes

  * Use this at your own risk. No guarantees.
  * Contributions are welcome.
  * This /should/ work on MacOS the same way. But I haven't tested it.
  * A test on Windows shows that, yes it works. But with some quirks:
    * The menu `make menuconfig` renders a bit weird. Maybe the new Windows terminal will fix this.
    * The first `make app` will run just fine, but after that it fails to compile. Maybe some
      issue with the Windows CIFS mapping in Docker. However, you can skip this step and run `xbuild-project`
      instead. That will only compile the rust part.
  * In theory this should work also with with the ESP8266. A few tweaks for the build files
    will be required, and I didn't test this.
  * I put this on [quay.io](https:/quay.io) as Docker Hub continously failed to build this
    image. After several hours, the build times out. On quay.io it still takes around two hours
    but never times out.

## Also see

This work is built upn the work of others. Please see:

  * http://quickhack.net/nom/blog/2019-05-14-build-rust-environment-for-esp32.html
  * https://esp32.com/viewtopic.php?t=9226
  * https://github.com/MabezDev/rust-xtensa

