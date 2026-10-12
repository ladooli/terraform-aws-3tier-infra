set -e

exec > >(tee /var/log/user-data.log) 2>&1
echo "=== User data script started: $(date) ==="

echo "Updating system packages..."
dnf update -y

echo "Installing Docker..."
dnf install -y docker
systemctl start docker
systemctl enable docker

usermod -aG docker ec2-user

echo "Installing Docker Compose..."
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

mkdir -p /opt/app
cd /opt/app

echo "Writing docker-compose.yml..."
cat > docker-compose.yml << 'COMPOSE_EOF'
services:
  app1:
    image: ${ecr_app_repo}:latest
    container_name: app1
    restart: always

  app2:
    image: ${ecr_app_repo}:latest
    container_name: app2
    restart: always

  nginx:
    image: ${ecr_nginx_repo}:latest
    container_name: nginx-lb
    ports:
      - "80:80"
    depends_on:
      - app1
      - app2
    restart: always
COMPOSE_EOF

echo "Logging in to ECR..."
aws ecr get-login-password --region ${region} | \
  docker login --username AWS --password-stdin ${ecr_registry}

echo "Pulling images..."
docker pull ${ecr_app_repo}:latest
docker pull ${ecr_nginx_repo}:latest

echo "Starting containers..."
docker compose up -d

echo "Setup finished: $(date)"