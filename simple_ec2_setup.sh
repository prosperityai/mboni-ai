#!/bin/bash
set -e

# Simple setup script for MBONIAI on EC2
# This script will deploy MBONIAI directly on an EC2 instance

echo "===== MBONIAI Simple EC2 Setup Script ====="

# Make sure Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
  echo "You may need to log out and back in for docker group changes to take effect"
fi

# Make sure Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
  echo "Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

# Navigate to project directory and build images
cd ~/mboni-ai
mkdir -p docker/volumes/app/storage
mkdir -p docker/volumes/db/data
mkdir -p docker/volumes/redis/data
mkdir -p docker/volumes/weaviate

# Run the image rebuild script
echo "Building Docker images..."
cd docker
bash rebuild-images.sh

# Update docker-compose.yaml to use local images instead of ECR
echo "Updating docker-compose.yaml to use local images..."
sed -i 's|533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-api:latest|mboniai-api:latest|g' mboniai-compose.yaml
sed -i 's|533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-web:latest|mboniai-web:latest|g' mboniai-compose.yaml
sed -i 's|533267319731.dkr.ecr.us-east-1.amazonaws.com/mboniai-worker:latest|mboniai-worker:latest|g' mboniai-compose.yaml

# Start the application
echo "Starting MBONIAI..."
docker-compose -f mboniai-compose.yaml up -d

# Create a update script
cat > ~/update-mboniai.sh << 'EOF'
#!/bin/bash
cd ~/mboni-ai
git pull
cd docker
bash rebuild-images.sh
docker-compose -f mboniai-compose.yaml down
docker-compose -f mboniai-compose.yaml up -d
EOF
chmod +x ~/update-mboniai.sh

echo "===== Setup Complete ====="
echo "MBONIAI has been successfully deployed!"
echo "You can access it at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "To update in the future, run: ~/update-mboniai.sh"