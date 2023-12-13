echo "Downloading"
sleep 3

git clone https://github.com/its-a-feature/Mythic.git
cd Mythic

echo "Building" 
sleep 3

build = "sudo make"

echo $build | sh

./mythic-cli start
