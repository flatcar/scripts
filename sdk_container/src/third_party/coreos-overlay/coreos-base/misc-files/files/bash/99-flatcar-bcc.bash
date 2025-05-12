for iovisor_bcc_tool in tcpretrans tcpconnect tcpaccept biolatency; do
    alias "iovisor-${iovisor_bcc_tool}=docker run --rm -it -v /lib/modules:/lib/modules -v /sys/kernel/debug:/sys/kernel/debug -v /sys/fs/cgroup:/sys/fs/cgroup -v /sys/fs/bpf:/sys/fs/bpf --privileged --net host --pid host quay.io/iovisor/bcc /usr/share/bcc/tools/${iovisor_bcc_tool}"
done

unset -v iovisor_bcc_tool
