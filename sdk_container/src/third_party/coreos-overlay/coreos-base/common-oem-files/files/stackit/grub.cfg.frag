# STACKIT logs by default to the serial console, map ttyS0 also to the system console.
if [ "$grub_cpu" = x86_64 ]; then
  set linux_console="console=tty0 console=ttyS0,115200n8"
fi
