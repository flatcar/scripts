set linux_append="flatcar.autologin"

if [ "$grub_cpu" = i386 ] || [ "$grub_cpu" = x86_64 ]; then
    set gfxpayload="1024x768x8,1024x768"
    set linux_console="console=tty0 console=ttyS1,115200n8"
fi
