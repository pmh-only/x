CLUSTER_NAME=wsi-cluster

REGION=$(curl -H "X-aws-ec2-metadata-token: `curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`" http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

OIDC_URL=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text)

cat <<EOF > trust_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_URL"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$OIDC_URL:sub": "system:serviceaccount:argocd:argocd-image-update"
        }
      }
    }
  ]
}
EOF

ROLE_ARN=$(aws iam create-role \
  --role-name $CLUSTER_NAME-argocd-updater \
  --assume-role-policy-document file://trust_policy.json \
  --query "Role.Arn" \
  --output text)

aws iam attach-role-policy \
  --role-name $CLUSTER_NAME-argocd-updater \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

wget https://raw.githubusercontent.com/pmh-only/x/refs/heads/main/k8s/addon_install/templates/argocd_image_updater.yml -O argocd_image_updater.yml

sed -i -e "s/<REGION>/$REGION/g" argocd_image_updater.yml
sed -i -e "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" argocd_image_updater.yml
sed -i -e "s%<ROLE_ARN>%$ROLE_ARN%g" argocd_image_updater.yml

kubectl apply -n argocd -f argocd_image_updater.yml
