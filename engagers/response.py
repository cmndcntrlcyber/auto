"""
Incident Response Triage Module

Automated host investigation playbook that collects volatile data, analyzes
system state, and produces a structured triage report. Designed for first-
responder use on Linux hosts during potential compromise investigations.

SECURITY WARNING: This tool is designed for authorized incident response
and defensive security operations only.

Author: Security Automation Team
Version: 1.0.0
License: MIT
"""

import subprocess
import os
import sys
import json
import logging
import socket
import datetime
import getpass
import platform
from typing import Dict, List, Any, Optional, Tuple
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("ir_triage.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)

# Severity levels for findings
SEVERITY_CRITICAL = "CRITICAL"
SEVERITY_HIGH = "HIGH"
SEVERITY_MEDIUM = "MEDIUM"
SEVERITY_LOW = "LOW"
SEVERITY_INFO = "INFO"


def run_cmd(cmd: str, timeout: int = 30) -> Tuple[str, str, int]:
    """Run a shell command and return stdout, stderr, returncode."""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", f"Command timed out after {timeout}s: {cmd}", -1
    except Exception as e:
        return "", str(e), -1


class Finding:
    """A single triage finding."""

    def __init__(self, title: str, severity: str, category: str,
                 details: str, recommendation: str = ""):
        self.title = title
        self.severity = severity
        self.category = category
        self.details = details
        self.recommendation = recommendation
        self.timestamp = datetime.datetime.now().isoformat()

    def to_dict(self) -> Dict[str, str]:
        return {
            "title": self.title,
            "severity": self.severity,
            "category": self.category,
            "details": self.details,
            "recommendation": self.recommendation,
            "timestamp": self.timestamp,
        }

    def __str__(self) -> str:
        rec = f"\n  Recommendation: {self.recommendation}" if self.recommendation else ""
        return f"[{self.severity}] {self.title}\n  {self.details}{rec}"


class IncidentResponseTriage:
    """
    Automated incident response triage collector.

    Gathers volatile host data across multiple categories and flags
    anomalies as findings with severity ratings.
    """

    def __init__(self, output_dir: Optional[str] = None):
        self.hostname = socket.gethostname()
        self.user = getpass.getuser()
        self.timestamp = datetime.datetime.now()
        self.has_sudo = self._check_sudo()
        self.findings: List[Finding] = []
        self.collection: Dict[str, Any] = {}

        if output_dir:
            self.output_dir = Path(output_dir)
        else:
            self.output_dir = Path(f"ir_triage_{self.hostname}_{self.timestamp:%Y%m%d_%H%M%S}")

    def _check_sudo(self) -> bool:
        """Check if we can run sudo without a password."""
        _, _, rc = run_cmd("sudo -n true 2>/dev/null", timeout=5)
        return rc == 0

    def _add_finding(self, title: str, severity: str, category: str,
                     details: str, recommendation: str = ""):
        finding = Finding(title, severity, category, details, recommendation)
        self.findings.append(finding)
        logger.info(f"Finding: [{severity}] {title}")

    # ------------------------------------------------------------------
    # Collection modules
    # ------------------------------------------------------------------

    def collect_system_info(self) -> Dict[str, str]:
        """Collect basic system identification."""
        logger.info("Collecting system info...")
        info = {
            "hostname": self.hostname,
            "user": self.user,
            "platform": platform.platform(),
            "kernel": platform.release(),
            "arch": platform.machine(),
            "timestamp": self.timestamp.isoformat(),
            "has_sudo": str(self.has_sudo),
        }
        uptime, _, _ = run_cmd("uptime -p")
        info["uptime"] = uptime

        boot_time, _, _ = run_cmd("who -b")
        info["boot_time"] = boot_time.strip()

        self.collection["system_info"] = info
        return info

    def collect_users_and_sessions(self) -> Dict[str, str]:
        """Collect user session data and check for anomalies."""
        logger.info("Collecting user and session data...")
        data: Dict[str, str] = {}

        data["who"], _, _ = run_cmd("who")
        data["w"], _, _ = run_cmd("w")
        data["last_25"], _, _ = run_cmd("last -25")

        if self.has_sudo:
            data["lastb_25"], _, _ = run_cmd("sudo lastb 2>/dev/null | head -25")
        else:
            data["lastb_25"] = "(requires sudo)"

        # Users with login shells
        shell_users, _, _ = run_cmd(
            "grep -v '/nologin\\|/false' /etc/passwd"
        )
        data["shell_users"] = shell_users

        # Flag unexpected shell users
        for line in shell_users.splitlines():
            parts = line.split(":")
            if len(parts) >= 3:
                username = parts[0]
                uid = int(parts[2]) if parts[2].isdigit() else -1
                if uid >= 1000 and uid < 65534 and username not in ("nobody",):
                    # Regular user – not inherently suspicious, just collect
                    pass
                elif uid == 0 and username != "root":
                    self._add_finding(
                        f"UID-0 account: {username}",
                        SEVERITY_CRITICAL,
                        "users",
                        f"Non-root account with UID 0: {line}",
                        "Investigate immediately – possible backdoor account.",
                    )

        # Check for failed logins
        if self.has_sudo:
            lastb_out = data.get("lastb_25", "")
            if lastb_out and lastb_out != "(requires sudo)":
                fail_count = len([l for l in lastb_out.splitlines() if l.strip()])
                if fail_count > 10:
                    self._add_finding(
                        f"{fail_count} failed login attempts",
                        SEVERITY_MEDIUM,
                        "users",
                        f"Recent failed logins detected:\n{lastb_out[:500]}",
                        "Review source IPs and usernames for brute-force patterns.",
                    )

        self.collection["users_sessions"] = data
        return data

    def collect_network(self) -> Dict[str, str]:
        """Collect network connections, listeners, and interfaces."""
        logger.info("Collecting network data...")
        data: Dict[str, str] = {}

        prefix = "sudo " if self.has_sudo else ""

        data["listening"], _, _ = run_cmd(f"{prefix}ss -tlnp")
        data["established"], _, _ = run_cmd(f"{prefix}ss -tnp state established")
        data["all_connections"], _, _ = run_cmd(f"{prefix}ss -anp")
        data["interfaces"], _, _ = run_cmd("ip addr show")
        data["routes"], _, _ = run_cmd("ip route")
        data["dns"], _, _ = run_cmd("cat /etc/resolv.conf")
        data["hosts"], _, _ = run_cmd("cat /etc/hosts")

        # Analyze listeners bound to all interfaces (0.0.0.0 or ::)
        for line in data["listening"].splitlines():
            parts = line.split()
            if len(parts) < 4:
                continue
            addr = parts[3]
            # Only flag services bound to all interfaces, not localhost
            if not (addr.startswith("0.0.0.0:") or addr.startswith("*:") or addr == ":::*"):
                continue
            process_info = parts[-1] if "users:" in parts[-1] else "unknown"
            # Skip well-known safe listeners
            if any(safe in process_info for safe in ("systemd-resolve", "cupsd")):
                continue
            self._add_finding(
                f"Service listening on all interfaces: {addr}",
                SEVERITY_MEDIUM,
                "network",
                f"Binding: {addr} — {process_info}",
                "Verify this service should be exposed. Bind to specific IP if possible.",
            )

        # Check for connections without process attribution
        for line in data["established"].splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("Recv-Q") or stripped.startswith("State"):
                continue
            if "users:(" not in line:
                parts = stripped.split()
                # Need at least local + peer address columns
                if len(parts) >= 4:
                    remote = parts[3]
                    self._add_finding(
                        f"Unattributed connection to {remote}",
                        SEVERITY_HIGH,
                        "network",
                        f"Established connection with no owning process visible:\n{stripped}",
                        "Run with root privileges for full attribution. "
                        "Investigate the remote IP for threat intelligence.",
                    )

        self.collection["network"] = data
        return data

    def collect_processes(self) -> Dict[str, str]:
        """Collect running processes and check for anomalies."""
        logger.info("Collecting process data...")
        data: Dict[str, str] = {}

        data["ps_tree"], _, _ = run_cmd("ps auxf --sort=-%cpu")
        data["process_count"], _, _ = run_cmd("ps aux | wc -l")

        # Check for processes running from suspicious locations
        proc_tmp, _, _ = run_cmd(
            "ls -la /proc/*/exe 2>/dev/null | grep -E '(/tmp/|/dev/shm/|/var/tmp/)'"
        )
        data["procs_from_tmp"] = proc_tmp
        if proc_tmp.strip():
            self._add_finding(
                "Process running from temp directory",
                SEVERITY_CRITICAL,
                "processes",
                f"Binaries executing from /tmp, /dev/shm, or /var/tmp:\n{proc_tmp}",
                "Investigate immediately. Capture binary for analysis.",
            )

        # Check for deleted binaries still running
        deleted, _, _ = run_cmd(
            "ls -la /proc/*/exe 2>/dev/null | grep '(deleted)'"
        )
        data["deleted_binaries"] = deleted
        if deleted.strip():
            self._add_finding(
                "Running process with deleted binary",
                SEVERITY_HIGH,
                "processes",
                f"Processes whose on-disk binary has been removed:\n{deleted}",
                "Could indicate a replaced/updated binary or attacker cleanup. Investigate PIDs.",
            )

        self.collection["processes"] = data
        return data

    def collect_persistence(self) -> Dict[str, str]:
        """Check common persistence mechanisms."""
        logger.info("Collecting persistence data...")
        data: Dict[str, str] = {}

        # Cron
        data["crontab_user"], _, _ = run_cmd("crontab -l 2>/dev/null")
        if self.has_sudo:
            data["crontab_root"], _, _ = run_cmd("sudo crontab -l 2>/dev/null")
        data["cron_d"], _, _ = run_cmd("ls -la /etc/cron.d/")
        data["cron_daily"], _, _ = run_cmd("ls -la /etc/cron.daily/")
        data["cron_hourly"], _, _ = run_cmd("ls -la /etc/cron.hourly/")

        # Systemd user services
        user_services, _, _ = run_cmd(
            f"ls ~/.config/systemd/user/ 2>/dev/null"
        )
        data["systemd_user"] = user_services
        if user_services.strip():
            self._add_finding(
                "User-level systemd services found",
                SEVERITY_MEDIUM,
                "persistence",
                f"Services in ~/.config/systemd/user/:\n{user_services}",
                "Review each service for legitimacy.",
            )

        # Enabled system services
        data["enabled_services"], _, _ = run_cmd(
            "systemctl list-unit-files --type=service --state=enabled"
        )

        # Failed services
        data["failed_services"], _, _ = run_cmd("systemctl --failed")

        # XDG autostart
        data["xdg_autostart_user"], _, _ = run_cmd("ls -la ~/.config/autostart/ 2>/dev/null")
        data["xdg_autostart_system"], _, _ = run_cmd("ls -la /etc/xdg/autostart/ 2>/dev/null")

        # rc.local
        rc_local, _, _ = run_cmd("cat /etc/rc.local 2>/dev/null")
        data["rc_local"] = rc_local
        if rc_local.strip() and "exit 0" not in rc_local.replace(" ", ""):
            self._add_finding(
                "/etc/rc.local contains commands",
                SEVERITY_MEDIUM,
                "persistence",
                f"Contents:\n{rc_local[:500]}",
                "Verify all commands are expected.",
            )

        self.collection["persistence"] = data
        return data

    def collect_filesystem(self) -> Dict[str, str]:
        """Check filesystem for suspicious artifacts."""
        logger.info("Collecting filesystem data...")
        data: Dict[str, str] = {}

        # Temp directories
        data["tmp"], _, _ = run_cmd("ls -la /tmp/")
        data["var_tmp"], _, _ = run_cmd("ls -la /var/tmp/")
        data["dev_shm"], _, _ = run_cmd("ls -la /dev/shm/")

        # Recently modified files in key directories (last 24h)
        prefix = "sudo " if self.has_sudo else ""
        recent, _, _ = run_cmd(
            f"{prefix}find /etc /usr/local/bin /usr/bin -maxdepth 2 "
            f"-mtime -1 -type f 2>/dev/null | head -60"
        )
        data["recently_modified"] = recent
        if recent.strip():
            self._add_finding(
                "Recently modified files in system directories",
                SEVERITY_HIGH,
                "filesystem",
                f"Files changed in last 24h:\n{recent}",
                "Review each modification. Compare against package manager records.",
            )

        # SUID/SGID binaries
        suid, _, _ = run_cmd(
            f"{prefix}find / -maxdepth 4 -perm -4000 -type f 2>/dev/null | head -40"
        )
        data["suid_binaries"] = suid

        # World-writable files in /etc
        world_w, _, _ = run_cmd(
            f"{prefix}find /etc -maxdepth 2 -perm -o+w -type f 2>/dev/null | head -20"
        )
        data["world_writable_etc"] = world_w
        if world_w.strip():
            self._add_finding(
                "World-writable files in /etc",
                SEVERITY_MEDIUM,
                "filesystem",
                f"Files:\n{world_w}",
                "Fix permissions. World-writable config files can be tampered with by any user.",
            )

        # Root-owned files in user home
        root_in_home, _, _ = run_cmd(
            f"find {Path.home()} -maxdepth 2 -user root -type f 2>/dev/null | head -20"
        )
        data["root_owned_in_home"] = root_in_home
        if root_in_home.strip():
            self._add_finding(
                "Root-owned files in user home directory",
                SEVERITY_LOW,
                "filesystem",
                f"Files:\n{root_in_home}",
                "May indicate mixed-privilege usage. Chown to user or investigate.",
            )

        self.collection["filesystem"] = data
        return data

    def collect_auth_and_logs(self) -> Dict[str, str]:
        """Collect authentication and system logs."""
        logger.info("Collecting auth and log data...")
        data: Dict[str, str] = {}

        if self.has_sudo:
            data["auth_log"], _, _ = run_cmd(
                "sudo tail -100 /var/log/auth.log 2>/dev/null"
            )
            data["syslog_warnings"], _, _ = run_cmd(
                'sudo journalctl -p warning --since "24 hours ago" 2>/dev/null | tail -50'
            )
        else:
            data["auth_log"] = "(requires sudo)"
            data["syslog_warnings"], _, _ = run_cmd(
                'journalctl -p warning --since "24 hours ago" 2>/dev/null | tail -50'
            )

        # Package install history
        data["dpkg_log"], _, _ = run_cmd(
            "grep ' install ' /var/log/dpkg.log 2>/dev/null | tail -30"
        )

        self.collection["auth_logs"] = data
        return data

    def collect_shell_config(self) -> Dict[str, str]:
        """Inspect shell configs for injected commands."""
        logger.info("Collecting shell configuration data...")
        data: Dict[str, str] = {}

        home = Path.home()
        shell_files = [".bashrc", ".bash_profile", ".profile", ".zshrc", ".bash_aliases"]

        for sf in shell_files:
            path = home / sf
            if path.exists():
                content, _, _ = run_cmd(f"cat {path}")
                data[sf] = content
                stat_out, _, _ = run_cmd(f"stat {path}")
                data[f"{sf}_stat"] = stat_out

                # Flag suspicious patterns (skip known-safe defaults)
                safe_eval_patterns = [
                    'eval "$(dircolors',
                    "eval \"$(SHELL=/bin/sh lesspipe)\"",
                    'eval "$(lesspipe',
                ]
                suspicious = [
                    "curl ", "wget ", "nc ", "ncat ", "netcat ",
                    "/dev/tcp/", "base64", "eval ", "python -c",
                    "perl -e", "ruby -e", "exec ",
                ]
                for pattern in suspicious:
                    if pattern not in content:
                        continue
                    # Check each matching line to filter safe defaults
                    flagged_lines = []
                    for content_line in content.splitlines():
                        if pattern not in content_line:
                            continue
                        if content_line.strip().startswith("#"):
                            continue
                        if any(safe in content_line for safe in safe_eval_patterns):
                            continue
                        flagged_lines.append(content_line.strip())
                    if flagged_lines:
                        self._add_finding(
                            f"Suspicious pattern in ~/{sf}: '{pattern.strip()}'",
                            SEVERITY_HIGH,
                            "shell_config",
                            f"Found '{pattern.strip()}' in {path}:\n"
                            + "\n".join(flagged_lines[:5]),
                            "Review the full file to determine if this is legitimate.",
                        )

        # LD_PRELOAD check
        ld_preload = os.environ.get("LD_PRELOAD", "")
        data["ld_preload_env"] = ld_preload
        if ld_preload:
            self._add_finding(
                "LD_PRELOAD is set",
                SEVERITY_CRITICAL,
                "shell_config",
                f"LD_PRELOAD={ld_preload}",
                "This can be used to hijack library calls. Investigate immediately.",
            )

        ld_preload_file, _, _ = run_cmd("cat /etc/ld.so.preload 2>/dev/null")
        data["ld_so_preload"] = ld_preload_file
        if ld_preload_file.strip():
            self._add_finding(
                "/etc/ld.so.preload contains entries",
                SEVERITY_CRITICAL,
                "shell_config",
                f"Contents: {ld_preload_file}",
                "This is a common rootkit persistence mechanism. Investigate immediately.",
            )

        self.collection["shell_config"] = data
        return data

    def collect_ssh(self) -> Dict[str, str]:
        """Check SSH configuration and keys."""
        logger.info("Collecting SSH data...")
        data: Dict[str, str] = {}

        # Authorized keys
        auth_keys_path = Path.home() / ".ssh" / "authorized_keys"
        if auth_keys_path.exists():
            data["authorized_keys"], _, _ = run_cmd(f"cat {auth_keys_path}")
            key_count = len([
                l for l in data["authorized_keys"].splitlines() if l.strip() and not l.startswith("#")
            ])
            data["authorized_key_count"] = str(key_count)
        else:
            data["authorized_keys"] = "(no file)"
            data["authorized_key_count"] = "0"

        # Known hosts
        known_hosts_path = Path.home() / ".ssh" / "known_hosts"
        if known_hosts_path.exists():
            kh_count, _, _ = run_cmd(f"wc -l < {known_hosts_path}")
            data["known_hosts_count"] = kh_count.strip()
        else:
            data["known_hosts_count"] = "0"

        # SSH config
        data["sshd_config"], _, _ = run_cmd(
            "cat /etc/ssh/sshd_config 2>/dev/null | grep -v '^#' | grep -v '^$'"
        )

        # Check for password auth enabled
        if "PasswordAuthentication yes" in data.get("sshd_config", ""):
            self._add_finding(
                "SSH password authentication enabled",
                SEVERITY_MEDIUM,
                "ssh",
                "PasswordAuthentication is set to yes in sshd_config.",
                "Consider disabling in favor of key-based auth.",
            )

        self.collection["ssh"] = data
        return data

    def collect_docker(self) -> Dict[str, str]:
        """Check Docker state."""
        logger.info("Collecting Docker data...")
        data: Dict[str, str] = {}

        data["containers"], _, rc = run_cmd("docker ps -a 2>/dev/null")
        if rc != 0:
            data["containers"] = "(docker not accessible)"
        data["images"], _, _ = run_cmd("docker images 2>/dev/null | head -20")

        self.collection["docker"] = data
        return data

    def collect_kernel_modules(self) -> Dict[str, str]:
        """Check loaded kernel modules."""
        logger.info("Collecting kernel module data...")
        data: Dict[str, str] = {}

        data["lsmod"], _, _ = run_cmd("lsmod")

        self.collection["kernel_modules"] = data
        return data

    def collect_pam_sudoers(self) -> Dict[str, str]:
        """Check PAM and sudoers for backdoors."""
        logger.info("Collecting PAM/sudoers data...")
        data: Dict[str, str] = {}

        pam_exec, _, _ = run_cmd(
            "grep -r 'pam_exec\\|pam_script\\|pam_python' /etc/pam.d/ 2>/dev/null"
        )
        data["pam_suspicious"] = pam_exec
        if pam_exec.strip():
            self._add_finding(
                "Suspicious PAM module detected",
                SEVERITY_CRITICAL,
                "pam_sudoers",
                f"Potentially malicious PAM entries:\n{pam_exec}",
                "pam_exec/pam_script can execute arbitrary commands on auth. Investigate.",
            )

        data["sudoers_d"], _, _ = run_cmd("cat /etc/sudoers.d/* 2>/dev/null")

        self.collection["pam_sudoers"] = data
        return data

    # ------------------------------------------------------------------
    # Report generation
    # ------------------------------------------------------------------

    def generate_report(self) -> str:
        """Generate a text-based triage report."""
        lines: List[str] = []
        sep = "=" * 70

        lines.append(sep)
        lines.append("INCIDENT RESPONSE TRIAGE REPORT")
        lines.append(sep)
        lines.append(f"Host:      {self.hostname}")
        lines.append(f"User:      {self.user}")
        lines.append(f"Platform:  {platform.platform()}")
        lines.append(f"Kernel:    {platform.release()}")
        lines.append(f"Time:      {self.timestamp.isoformat()}")
        lines.append(f"Sudo:      {'yes' if self.has_sudo else 'no'}")
        lines.append(sep)
        lines.append("")

        # Findings summary
        lines.append("FINDINGS SUMMARY")
        lines.append("-" * 40)

        if not self.findings:
            lines.append("No anomalous findings detected.")
        else:
            by_severity = {}
            for f in self.findings:
                by_severity.setdefault(f.severity, []).append(f)

            for sev in [SEVERITY_CRITICAL, SEVERITY_HIGH, SEVERITY_MEDIUM, SEVERITY_LOW, SEVERITY_INFO]:
                if sev in by_severity:
                    lines.append(f"\n  {sev} ({len(by_severity[sev])}):")
                    for f in by_severity[sev]:
                        lines.append(f"    - {f.title}")
                        lines.append(f"      {f.details.splitlines()[0]}")
                        if f.recommendation:
                            lines.append(f"      >> {f.recommendation}")

        lines.append("")
        lines.append(sep)
        lines.append("COLLECTED DATA SECTIONS")
        lines.append(sep)

        for section_name, section_data in self.collection.items():
            lines.append(f"\n--- {section_name.upper().replace('_', ' ')} ---")
            if isinstance(section_data, dict):
                for key, value in section_data.items():
                    val_str = str(value)
                    if len(val_str) > 2000:
                        val_str = val_str[:2000] + "\n... (truncated)"
                    lines.append(f"\n[{key}]")
                    lines.append(val_str if val_str else "(empty)")
            else:
                lines.append(str(section_data))

        lines.append("")
        lines.append(sep)
        lines.append("END OF REPORT")
        lines.append(sep)

        return "\n".join(lines)

    def save_results(self):
        """Save collection data and report to output directory."""
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Save raw collection as JSON
        json_path = self.output_dir / "triage_data.json"
        with open(json_path, "w") as f:
            json.dump(self.collection, f, indent=2, default=str)
        logger.info(f"Raw data saved to {json_path}")

        # Save findings as JSON
        findings_path = self.output_dir / "findings.json"
        with open(findings_path, "w") as f:
            json.dump([fd.to_dict() for fd in self.findings], f, indent=2)
        logger.info(f"Findings saved to {findings_path}")

        # Save text report
        report_path = self.output_dir / "triage_report.txt"
        with open(report_path, "w") as f:
            f.write(self.generate_report())
        logger.info(f"Report saved to {report_path}")

        return self.output_dir

    # ------------------------------------------------------------------
    # Main execution
    # ------------------------------------------------------------------

    def run(self):
        """Execute the full triage playbook."""
        print("=" * 60)
        print("Incident Response Triage v1.0.0")
        print("=" * 60)

        if not self.has_sudo:
            print("\n[!] Running without sudo — some checks will be limited.")
            print("    For full coverage, run with passwordless sudo or as root.\n")

        modules = [
            ("System Info", self.collect_system_info),
            ("Users & Sessions", self.collect_users_and_sessions),
            ("Network", self.collect_network),
            ("Processes", self.collect_processes),
            ("Persistence", self.collect_persistence),
            ("Filesystem", self.collect_filesystem),
            ("Auth & Logs", self.collect_auth_and_logs),
            ("Shell Config", self.collect_shell_config),
            ("SSH", self.collect_ssh),
            ("Docker", self.collect_docker),
            ("Kernel Modules", self.collect_kernel_modules),
            ("PAM & Sudoers", self.collect_pam_sudoers),
        ]

        total = len(modules)
        for i, (name, func) in enumerate(modules, 1):
            print(f"[{i}/{total}] Collecting: {name}...")
            try:
                func()
            except Exception as e:
                logger.error(f"Error in {name}: {e}")
                self._add_finding(
                    f"Collection error in {name}",
                    SEVERITY_INFO,
                    "collection",
                    str(e),
                )

        # Generate and display report
        print(f"\n{'=' * 60}")
        print(f"Collection complete. {len(self.findings)} finding(s) detected.")
        print(f"{'=' * 60}\n")

        report = self.generate_report()
        print(report)

        # Save results
        output_path = self.save_results()
        print(f"\nResults saved to: {output_path}/")

        return self.findings


def main():
    """Entry point for the triage script."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Incident Response Triage — automated host investigation playbook"
    )
    parser.add_argument(
        "-o", "--output",
        help="Output directory for triage results",
        default=None,
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Suppress report output to stdout (still saved to file)",
    )
    args = parser.parse_args()

    if args.quiet:
        logging.getLogger().setLevel(logging.WARNING)

    triage = IncidentResponseTriage(output_dir=args.output)
    findings = triage.run()

    # Exit with non-zero if critical/high findings exist
    critical_high = [f for f in findings if f.severity in (SEVERITY_CRITICAL, SEVERITY_HIGH)]
    if critical_high:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
