wget https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/scripts/fresh-ubun.sh
bash fresh-ubun.sh

wget https://github.com/supabase/cli/releases/download/v1.133.3/supabase_1.133.3_linux_amd64.deb
dpkg -i supabase_1.133.3_linux_amd64.deb

apt-get install -y snapd
sudo snap install code --classic

supabase init

supabase start