#!/bin/sh
sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
sudo docker run --privileged --rm tonistiigi/binfmt --install all

sudo sh -c '
cat <<EOF > /etc/systemd/system/binfmt-qemu.service
[Unit]
Description=Register binfmt for qemu
After=proc-sys-fs-binfmt_misc.mount

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --privileged --rm tonistiigi/binfmt --install arm64

[Install]
WantedBy=multi-user.target
EOF
'

sudo systemctl enable --now binfmt-qemu
