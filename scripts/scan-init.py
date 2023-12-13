import subprocess
import os
from pathlib import Path
from lxml import etree

def run_nmap_scan(target, ports, name, scan_type, extra_args=""):
    filename = f"vuln.{scan_type}.{name}.xml"
    html_filename = filename.replace('.xml', '.html')
    nmap_command = f"sudo nmap {target} {ports} -f -T5 -v5 -Pn -sV -sC -O {extra_args} -oX {filename}"
    subprocess.run(nmap_command, shell=True)
    xsltproc_command = f"xsltproc {filename} -o {html_filename}"
    subprocess.run(xsltproc_command, shell=True)
    os.remove(filename)

def main():
    target = input("What's the IP range of your target? ")
    ports = input("Which ports? ")
    name = input("What's the name of your target? ")
    print(f"The target is {target}, the ports are: {ports}, and the target/file name will be: {name}")

    base_path = Path(f"/home/<USERNAME>/rslts/{name}/vuln")
    base_path.mkdir(parents=True, exist_ok=True)
    os.chdir(base_path)

    run_nmap_scan(target, ports, name, "smb-brute", "--script smb-brute.nse")
    run_nmap_scan(target, ports, name, "init")
    run_nmap_scan(target, ports, name, "vulners", "--script vulners --script-args mincvss=5.0")
    run_nmap_scan(target, ports, name, "dns-enum", "--script dns-srv-enum  --script-args 'dns-srv-enum.domain'")
    run_nmap_scan(target, ports, name, "exploit", "--script exploit --script-args 'exploit.intensive'")
    run_nmap_scan(target, ports, name, "http-enum", "--script http-enum --script-args 'http-enum.category'")
    run_nmap_scan(target, ports, name, "ssh-pubkey", "--script ssh-publickey-acceptance")

    print("Done!")

if __name__ == "__main__":
    main()