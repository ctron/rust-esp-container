# Rust ESP compiler container

This is a container which can be used to build a Rust project for the ESP32.

## Pre-requisites

  * Docker
  * A rust project (e.g. use [ctron/rust-esp-template](https://github.com/ctron/rust-esp-template) as example)

## Usage

This container image provides a few tools which can be run like this:

    docker run -ti -v $PWD:/build:z quay.io/ctron/rust-esp

The `-v $PWD:/build:z` will map the current directory into the location `/build` inside the container.
This is required so that the tools inside the container can work with the project.

The `$PWD` part uses the current directory. This will only work in a Bourne like shell. You can replace
this with the absolute path to your project instead.

You can drop the `:z` suffix, if you don't have SElinux on the host system.

All following example assue that you use `$PWD:/build:z`.

This will run the default command `build-project`. You can run other commands, e.g. `bash` like this:

    docker run -ti -v $PWD:/build:z quay.io/ctron/rust-esp bash

## Bootstrapping

Initially a few files need to be set up. The ESP-IDF components need to be configured and compiled.
Run the following command to create an initial setup:

    docker run -ti -v $PWD:/build:z quay.io/ctron/rust-esp create-project

This will create (overwrite) as few files which are required to build the project.
Next run:

    docker run -ti -v $PWD:/build:z quay.io/ctron/rust-esp make menuconfig

Which will start the ESP-IDF build and shows you the menu config tool for configuring
your ESP project. Be sure to save when you exit.

## Building

In order to build the project, run the following command:

    docker run -ti -v $PWD:/build:z quay.io/ctron/rust-esp

This will compile the ESP-IDF part, the rust part and finally convert it to an image
which you can upload to your ESP.

## Uploading

You can then upload the image using an `esptool` on any machnine. As it might be difficult to do this
from inside the container, it is recommended to do this on the host system:

    esptool write_flash 0x10000 esp-app.bin

## Building the container

You can also build the container image yourself, by cloning this repository and executing:

    docker build . -t rust-esp

## Notes

  * Use this at your own risk. No guarantees.
  * This /should/ work on Windows and MacOS the same way. But I haven't tested it.

## Also see

  * http://quickhack.net/nom/blog/2019-05-14-build-rust-environment-for-esp32.html
  * https://esp32.com/viewtopic.php?t=9226
  * https://github.com/MabezDev/rust-xtensa

