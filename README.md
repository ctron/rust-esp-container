# Rust Compiler Image

Compile project:

    rustup run xtensa xargo build --target xtensa-esp32-none-elf

Convert to image:

    $IDF_PATH/components/esptool_py/esptool/esptool.py --chip esp32 elf2image --flash_mode dio --flash_freq 40m --flash_size 2MB -o esp32-hello.bin target/xtensa-esp32-none-elf/debug/esp32-test


