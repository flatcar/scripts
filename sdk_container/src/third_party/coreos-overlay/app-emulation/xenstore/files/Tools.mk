# Tools path
BISON               :=
FLEX                :=
PYTHON              := # overridden in ebuild
PYTHON_PATH         :=
PY_NOOPT_CFLAGS     :=
PERL                := # overridden in ebuild
BASH                :=
XGETTTEXT           :=
AS86                :=
LD86                :=
BCC                 :=
IASL                :=
AWK                 := # overridden in ebuild
FETCHER             :=

# Extra folder for libs/includes
PREPEND_INCLUDES    :=
PREPEND_LIB         :=
APPEND_INCLUDES     :=
APPEND_LIB          :=

PTHREAD_CFLAGS      := -pthread
PTHREAD_LDFLAGS     := -pthread
PTHREAD_LIBS        :=

PTYFUNCS_LIBS       :=

LIBNL3_LIBS         :=
LIBNL3_CFLAGS       :=
XEN_TOOLS_RPATH     := n

# Download GIT repositories via HTTP or GIT's own protocol?
# GIT's protocol is faster and more robust, when it works at all (firewalls
# may block it). We make it the default, but if your GIT repository downloads
# fail or hang, please pass --enable-githttp to configure.
GIT_HTTP            ?= n

# Optional components
XENSTAT_XENTOP      := n
OCAML_TOOLS         := n
FLASK_POLICY        := y # TODO
CONFIG_OVMF         := n
CONFIG_ROMBIOS      := n
CONFIG_SEABIOS      := n
CONFIG_IPXE         := n
CONFIG_QEMU_TRAD    := n
CONFIG_QEMU_XEN     := n
CONFIG_QEMUU_EXTRA_ARGS :=
CONFIG_LIBNL        := n
CONFIG_GOLANG       := n

CONFIG_SYSTEMD      := n
SYSTEMD_CFLAGS      :=
SYSTEMD_LIBS        :=
XEN_SYSTEMD_DIR     :=
XEN_SYSTEMD_MODULES_LOAD :=
CONFIG_9PFS         :=

LINUX_BACKEND_MODULES :=

#System options
ZLIB                :=
CONFIG_LIBICONV     := n
EXTFS_LIBS          :=
CURSES_LIBS         :=
TINFO_LIBS          :=
ARGP_LDFLAGS        :=

FILE_OFFSET_BITS    :=

CONFIG_PV_SHIM      := n
