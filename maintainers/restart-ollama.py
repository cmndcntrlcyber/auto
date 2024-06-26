import sys
import subprocess
import re

# variables

# stop_ollama_service = "systemctl stop ollama" #comment out if your first install

fix_nvidia = "sudo nvidia-ctk runtime configure --runtime=docker" 
restart_docker = "sudo systemctl restart docker"

start_ollama_docker = "docker run -d --runtime=nvidia --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama-localhost ollama/ollama"

get_ollama_ip = "docker inspect ollama-localhost | grep 'IPAddress'"
pattern = r'\"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"'

match = re.search(pattern, subprocess.check_output(get_ollama_ip, shell=True).decode())

ollama_ip = match.group(1) if match else None
if ollama_ip is not None:
    print("IP Address: ", ollama_ip)
else:
    print("No IP address found")
    sys.exit()

start_open_webui = "docker run -d -p 3000:8080 -e OLLAMA_API_BASE_URL=http://" + str(ollama_ip) + ":11434/api -v open-webui:/app/backend/data --name open-webui-localhost --restart always open-webui:latest"

find_live_container1 = "docker ps -a --filter 'name=ollama' --format 'table {{.ID}}' | awk 'NR!=1'"
find_live_container2 = "docker ps -a --filter 'name=open-webui' --format 'table {{.ID}}' | awk 'NR!=1'"

live_container1 = subprocess.check_output(find_live_container1, shell=True)
live_container2 = subprocess.check_output(find_live_container2, shell=True)

output_str1 = live_container1.decode()
output_str2 = live_container2.decode()

print("OutputString1 = " + output_str1) 
print("OutputString2 = " + output_str2) 

stop_live_container1 = "docker stop " + output_str1
rm_live_container1 = "docker rm " + output_str1

stop_live_container2 = "docker stop " + output_str2
rm_live_container2 = "docker rm " + output_str2

# stop ollama service: 
# subprocess.run(stop_ollama_service, shell=True) # comment out if your first install
# Fix Nvidia
subprocess.run(fix_nvidia, shell=True)
subprocess.run(restart_docker, shell=True)

# stop & remove running container
subprocess.run(stop_live_container1, shell=True)
subprocess.run(rm_live_container1, shell=True)

subprocess.run(stop_live_container2, shell=True)
subprocess.run(rm_live_container2, shell=True)

# restart container
subprocess.run(start_ollama_docker, shell=True)
subprocess.run(start_open_webui, shell=True)