# GCE only has a serial console.
set linux_console="console=ttyS0,115200n8"
serial com0 --speed=115200 --word=8 --parity=no
terminal_input serial_com0
terminal_output serial_com0
