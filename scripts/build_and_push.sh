set -e

REGION="eu-north-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "ECR URL-ek lekerdezese..."
APP_REPO=$(terraform -chdir=terraform output -raw ecr_app_url)
NGINX_REPO=$(terraform -chdir=terraform output -raw ecr_nginx_url)

echo "App repo:   $APP_REPO"
echo "Nginx repo: $NGINX_REPO"

echo ""
echo "Bejelentkezes az ECR-be..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

echo ""
echo "App image build es push..."
docker build -t week4-app ./app
docker tag week4-app:latest $APP_REPO:latest
docker push $APP_REPO:latest

echo ""
echo "Nginx image build es push..."
docker build -t week4-nginx ./nginx
docker tag week4-nginx:latest $NGINX_REPO:latest
docker push $NGINX_REPO:latest

echo ""
echo "✓ Mindket image sikeresen feltoltve az ECR-re!"
echo "  App:   $APP_REPO:latest"
echo "  Nginx: $NGINX_REPO:latest"
