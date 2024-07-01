import subprocess, os, shutil

type = input("What type of target is this? ")
target = input("What's the IP range of your target? ")
name = input("What's the name of your target? ")

def nmap_command(target):
    # Run the nmap command and capture its output
    output = subprocess.check_output(['nmap', '-p-', '--min-rate=1000', '-T4', target])
    # Find lines containing a port number
    ports = [line.strip().split('/')[0] for line in output.decode('utf-8').split('\n') if '/' in line]
    return ','.join(ports)

output = subprocess.check_output(['nmap', '-p-', '--min-rate=1000', '-T4', target])
# Find lines containing a port number
ports = [line.strip().split('/')[0] for line in output.decode('utf-8').split('\n') if '/' in line]

print("Making the Directories")

output_directory = "./targets/" + type + "/" + name  # Replace with your desired output directory path
if not os.path.exists(output_directory):
    print("Output directory does not exist.")
else:
    for file in os.listdir(os.getcwd()):
        if os.path.isfile(file) and "output" in file:  # Adjust the file filter as needed
            shutil.move(file, output_directory)

os.makedirs("/targets/" + type)
os.makedirs("/targets/" + type + "/" + name)
os.system("cp -r /engaged /targets/" + type + "/" + name)
os.chdir("/targets/" + type + "/" + name + "/engaged/recon/")

print("The target is " + target + " and the ports are: " + ports)

nmap_command('echo "' + target + ' ' + name + '" | sudo tee -a /etc/hosts')

# Run Nmap scans based on the ports provided by the nmap_command function
nmap_command('sudo nmap ' + target + ' -p' + ports + ' -T5 -v5 -sV -O --script ssl-cert -oX vuln.smb-brute.' + name + '.xml')
os.remove("vuln.smb-brute." + name + ".xml")

nmap_command('sudo nmap ' + target + ' -p' + ports + ' -T5 -v5 -sV -O --script exploit --script-args "exploit.intensive" -oX vuln.exploit.' + name + '.xml')
os.remove("vuln.exploit." + name + ".xml")

nmap_command('sudo nmap ' + target + ' -p' + ports + ' -T5 -v5 -sV -O --script http-enum --script-args "http-enum.category" -oX vuln.http-enum.' + name + '.xml')
os.remove("vuln.http-enum." + name + ".xml")

nmap_command('sudo nmap ' + target + ' -p' + ports + ' -T5 -v5 -sV -O --script ssh-publickey-acceptance -oX vuln.ssh-pubkey.' + name + '.xml')
os.remove("vuln.ssh-pubkey." + name + ".xml")

print("Done!")