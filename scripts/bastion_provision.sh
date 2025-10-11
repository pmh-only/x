#!/bin/bash
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

echo "Port 2222" >> /etc/ssh/sshd_config
systemctl restart sshd

yum install -y --allowerasing jq curl wget git mariadb1011 postgresql17 docker redis6

python3 -m ensurepip
python3 -m pip install parquet-tools

wget https://awscli.amazonaws.com/awscli-exe-linux-${archlg}.zip -O /tmp/awscliv2.zip
cd /tmp; unzip /tmp/awscliv2.zip; /tmp/aws/install

wget https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${archsm}/kubectl -O /tmp/kubectl
install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl

wget https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_linux_${archsm}.tar.gz -O /tmp/eksctl.tar.gz
tar -xzf /tmp/eksctl.tar.gz -C /tmp
install -o root -g root -m 0755 /tmp/eksctl /usr/local/bin/eksctl

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc

usermod -aG docker ec2-user
usermod -aG docker ssm-user

systemctl enable --now docker
mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
docker run --privileged --rm tonistiigi/binfmt --install all

sh -c '
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

systemctl enable --now binfmt-qemu
