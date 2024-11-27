mkdir "/opt/private-llm"

cd "/opt"

# Install NVIDIA Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update && sudo apt-get install -y nvidia-container-toolkit

# Install Cuda Toolkit
## For Ubuntu 2204 (Confirm required version)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.6.2/local_installers/cuda-repo-ubuntu2204-12-6-local_12.6.2-560.35.03-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-6-local_12.6.2-560.35.03-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-6

# Prepare Runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Install Ollama, Open-WebUI, Pipelines & Watchtower
curl https://raw.githubusercontent.com/cmndcntrlcyber/auto/refs/heads/main/configs/docker/compose%20templates/private-llm.docker-compose.yml > "/opt/private-llm/docker-compose.yml"
docker compose up -d