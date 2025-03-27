#!/bin/bash

BASEDIR=$(dirname "$(realpath "$0")")
TMPDIR=${TMPDIR:=/tmp}
IFACE=${IFACE:=alpn0}

generate_mac() {
    printf '%02x' $((RANDOM % 256 & 0xfe | 0x02))
    for i in {1..5}; do
        printf ':%02x' $((RANDOM % 256))
    done
    echo
}

#MONITOR="-display gtk"
#MONITOR="-display curses"
MONITOR="-nographic -serial mon:stdio"
#MONITOR="-chardev vc,id=monitor \
#  -mon monitor \
#  -serial vc
#"
#if [[ "$5" == "-d" ]]; then
#       printf -v VNC "-vnc :%d" $(( (($1 & 0xff)*0x100 + $2 & 0xff)|0x4000 ))
#       #VNC="-vnc :$((27000+$1))"
#       MONITOR="$VNC -daemonize -pidfile ${TMPDIR}/sgmtal0.pid"
#fi

sudo ip tuntap add dev ${IFACE} mode tap
#sudo ip link set dev sgmtal0 master sgmt
#sudo ip link set dev sgmtal0 up

mkdir -p ${TMPDIR}/sgmtal/media

KVM_FEATURES="--enable-kvm -machine type=pc,accel=kvm -cpu host"

qemu-system-x86_64 -snapshot $KVM_FEATURES -M q35 -m 512M \
    -smp 1,sockets=1,cores=1,threads=1 \
    -smbios type=1 \
    -virtfs local,path=${TMPDIR}/sgmtal/media,mount_tag=media,security_model=mapped-xattr \
    -netdev tap,id=net0,ifname=${IFACE},script=no,downscript=no \
    -device virtio-net-pci,netdev=net0,id=net0,mac="$(generate_mac)" \
    -drive file="${BASEDIR}/alpine.qcow2",if=virtio\
    $MONITOR

sudo ip link del ${IFACE}
