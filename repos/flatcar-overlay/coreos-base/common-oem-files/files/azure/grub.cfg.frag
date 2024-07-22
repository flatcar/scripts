set linux_append="flatcar.autologin"

# Azure only has a serial console.
serial --unit=0 --speed=115200 --word=8 --parity=no
terminal_input serial
terminal_output serial

if [ "$grub_cpu" = arm64 ]; then
  set linux_console="console=tty1 console=ttyAMA0,115200n8 earlycon=pl011,0xeffec000"
else
  set linux_console="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200"
fi
