#!/bin/bash

cat <<'EOF' >> ~/.bashrc

alias t="terraform"
alias ti="terraform init"
alias taa="terraform apply --auto-approve --parallelism 100"
alias td="terraform destroy --parallelism 100"
alias k="kubectl"
alias ka="kubectl apply -f"
alias kx="kubectl delete -f"
alias kd="kubectl describe -f"
alias kg="kubectl get pod -f"

export EDITOR="vim"

EOF

sudo su

uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

mkdir ~/.tmp

dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
dnf -y install terraform

wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${archsm}.tar.gz -O ~/.tmp/k9s.tar.gz
tar -xzf ~/.tmp/k9s.tar.gz -C ~/.tmp 
install -o root -g root -m 0755 ~/.tmp/k9s /usr/local/bin/k9s

mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
docker run --privileged --rm tonistiigi/binfmt --install all

exit