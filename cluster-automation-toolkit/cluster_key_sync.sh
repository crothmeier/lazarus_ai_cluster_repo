#!/bin/bash
set -euo pipefail

LOGFILE="${HOME}/.ssh/cluster_key_sync.log"
mkdir -p "$(dirname "$LOGFILE")"

log(){ echo "$(date '+%F %T') [$1] $2" | tee -a "$LOGFILE"; }

ensure_ssh_dir(){ [ -d ~/.ssh ] || { mkdir -p ~/.ssh && chmod 700 ~/.ssh; }; }

create_ed25519_key(){
    local kp=~/.ssh/id_ed25519
    if [[ -f $kp && -f $kp.pub ]]; then log INFO "SSH key exists"; return; fi
    log INFO "Generating ed25519 key"
    ssh-keygen -t ed25519 -f "$kp" -N "" -C "cluster key for $(whoami)@$(hostname) created on $(date +%F)"
    chmod 600 "$kp"; chmod 644 "$kp.pub"
}

usage(){ echo "Usage: $0 [--clean] [--hosts FILE]"; exit 1; }

CLEAN_MODE=0
HOSTS_FILE="${HOME}/.ssh/cluster_hosts"

parse_args(){
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clean) CLEAN_MODE=1 ;;
            --hosts) HOSTS_FILE="$2"; shift ;;
            *) usage ;;
        esac; shift
    done
}

push_keys_to_hosts(){
    local hosts_file="$1" pub_key=$(cat ~/.ssh/id_ed25519.pub)
    while IFS= read -r h || [[ -n "$h" ]]; do
        [[ "$h" =~ ^[[:space:]]*$|^# ]] && continue
        local user host port
        [[ "$h" == *"@"* ]] && { user="${h%%@*}"; h="${h#*@}"; } || user="$(whoami)"
        [[ "$h" == *":"* ]] && { host="${h%%:*}"; port="${h#*:}"; } || { host="$h"; port=22; }
        log INFO "Syncing key to $host"
        ping -c1 -W1 "$host" &>/dev/null || { log WARN "$host unreachable"; continue; }
        ssh-keygen -F "$host" &>/dev/null || ssh-keyscan -H -p "$port" "$host" >> ~/.ssh/known_hosts 2>/dev/null
        if ssh -o BatchMode=yes -p "$port" "$user@$host" "grep -q '${pub_key%% *}' ~/.ssh/authorized_keys 2>/dev/null"; then
            log INFO "Key already present on $host"
        else
            log INFO "Adding key to $host"
            ssh -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
            echo "$pub_key" | ssh -p "$port" "$user@$host" "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
        fi
    done < "$hosts_file"
}

# clean_stale_keys & cluster key funcs omitted for brevity...

main(){
    log INFO "cluster_key_sync.sh start"
    parse_args "$@"
    ensure_ssh_dir
    if [[ $CLEAN_MODE -eq 1 ]]; then
        log INFO "--clean not yet implemented in this snippet"
    else
        create_ed25519_key
        push_keys_to_hosts "$HOSTS_FILE"
    fi
    log INFO "Done"
}
main "$@"
