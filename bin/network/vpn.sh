#!/bin/bash

# =============================================================================
# VPN Script
# Run per-client VPNs (openfortivpn/openvpn) and sshuttle tunnels over them
# Clients live in ~/.config/vpn/<client>/, format in $DOTFILES/config/vpn/README.md
# Usage: vpn [up|down|status|list|edit|help] [<client>[/<tunnel>]]
# =============================================================================

set -uo pipefail

VPN_DIR="${VPN_DIR:-$HOME/.config/vpn}"
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}/vpn"
VPN_TIMEOUT="${VPN_TIMEOUT:-90}"
VPN_IFACE_RE='^(ppp|tun|wg)'
NAME_RE='^[A-Za-z0-9][A-Za-z0-9_.-]*$'
REMOTE_RE='^[A-Za-z0-9_][A-Za-z0-9_.@:-]*$'
SUBNET_RE='^[][A-Za-z0-9_.:/-]+$'
STATE_KEYS=(client tunnel wrapper wrapper_start pid pid_start start type config iface remote subnets owner log)
JQ_DEFS='def str: if . == "" then null else . end; def num: if . == "" then null else tonumber end; def words: split(" ") | map(select(. != ""));'

declare -A CONF=() P_PPID=() P_COMM=() RESOLVED=() IFACES=() CLAIMED=()
declare -A EXT_TYPE=() EXT_CONFIG=() EXT_REMOTE=() EXT_SUBNETS=()
EXT_VPNS=() EXT_TUNNELS=() ARGV=()
LOAD_ERR=""
STOPPED=0

warn() { echo "vpn: $*" >&2; }
die() { warn "$*"; exit 1; }
usage_die() { warn "$*"; echo "Run 'vpn help' for usage." >&2; exit 2; }
need() { command -v "$1" >/dev/null || die "$1 is required but not installed"; }

usage() {
  cat <<EOF
Usage: vpn [command] [target]

  vpn                         Pick a VPN or tunnel with fzf and bring it up
  vpn up <client>             Run the client VPN in the foreground (sudo, Ctrl-C stops it)
  vpn up <client>/<tunnel>    Run a sshuttle tunnel, starting the client VPN first if needed
  vpn down [<target>]         Stop a tunnel, a client (tunnels, then VPN) or everything
  vpn status [--json]         Show VPNs, tunnels, unmanaged sshuttle/VPNs and VPN interfaces
  vpn list                    List clients and tunnels
  vpn edit <target>           Open the client dir or a tunnel config in \$EDITOR

Config: $VPN_DIR
State:  $STATE_DIR
EOF
}

# --- Config ----------------------------------------------------

# Read key=value lines into CONF without sourcing them; remaining args are the allowed keys
parse_conf() {
  local file="$1" line key value n=0
  local allowed=" ${*:2} " dq='^"([^"]*)"$' sq="^'([^']*)'\$" kv='^([a-z_]+)[[:space:]]*=[[:space:]]*(.*)$'
  CONF=()
  [[ -r "$file" ]] || { LOAD_ERR="cannot read $file"; return 1; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" =~ $kv ]] || { LOAD_ERR="$file:$n: expected key=value"; return 1; }
    key="${BASH_REMATCH[1]}" value="${BASH_REMATCH[2]}"
    [[ "$allowed" == *" $key "* ]] || { LOAD_ERR="$file:$n: unknown key '$key'"; return 1; }
    [[ -z "${CONF[$key]+x}" ]] || { LOAD_ERR="$file:$n: duplicate key '$key'"; return 1; }
    if [[ "$value" =~ $dq || "$value" =~ $sq ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$value" == *[\"\']* ]]; then
      LOAD_ERR="$file:$n: unbalanced or embedded quote in '$key'"
      return 1
    fi
    CONF[$key]="$value"
  done < "$file"
}

list_clients() {
  local d
  for d in "$VPN_DIR"/*/; do
    d="${d%/}"
    [[ -f "$d/client.conf" ]] && echo "${d##*/}"
  done
}

list_tunnels() {
  local f
  for f in "$C_DIR"/tunnels/*.conf; do
    [[ -f "$f" ]] || continue
    f="${f##*/}"
    echo "${f%.conf}"
  done
}

# Sets C_* and V_*; V_TYPE stays empty for clients without vpn.conf
load_client() {
  local config
  LOAD_ERR=""
  [[ "$1" =~ $NAME_RE ]] || { LOAD_ERR="invalid client name '$1'"; return 1; }
  C_NAME="$1" C_DIR="$VPN_DIR/$1" C_LABEL="$1" C_COLOR=""
  V_TYPE="" V_CONFIG="" V_ARGS=()
  [[ -f "$C_DIR/client.conf" ]] || { LOAD_ERR="unknown client '$1' (no $C_DIR/client.conf)"; return 1; }
  parse_conf "$C_DIR/client.conf" label color || return 1
  C_LABEL="${CONF[label]:-$1}" C_COLOR="${CONF[color]:-}"
  if [[ -n "$C_COLOR" && ! "$C_COLOR" =~ ^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$ ]]; then
    LOAD_ERR="$C_DIR/client.conf: color must be #rrggbb"
    return 1
  fi
  [[ -f "$C_DIR/vpn.conf" ]] || return 0
  parse_conf "$C_DIR/vpn.conf" type config args || return 1
  case "${CONF[type]:-}" in
    openfortivpn|openvpn) V_TYPE="${CONF[type]}" ;;
    *) LOAD_ERR="$C_DIR/vpn.conf: type must be openfortivpn or openvpn"; return 1 ;;
  esac
  config="${CONF[config]:-}"
  [[ -n "$config" ]] || { LOAD_ERR="$C_DIR/vpn.conf: missing config="; V_TYPE=""; return 1; }
  [[ "$config" == /* ]] || config="$C_DIR/$config"
  [[ -f "$config" ]] || { LOAD_ERR="$C_DIR/vpn.conf: config file not found: $config"; V_TYPE=""; return 1; }
  V_CONFIG="$(realpath "$config")"
  read -ra V_ARGS <<< "${CONF[args]:-}"
}

# Sets T_* for a tunnel of the loaded client
load_tunnel() {
  local file tok
  LOAD_ERR=""
  [[ "$1" =~ $NAME_RE ]] || { LOAD_ERR="invalid tunnel name '$1'"; return 1; }
  T_NAME="$1" file="$C_DIR/tunnels/$1.conf"
  [[ -f "$file" ]] || { LOAD_ERR="unknown tunnel '$C_NAME/$1' (no $file)"; return 1; }
  parse_conf "$file" remote subnets exclude dns auto_nets needs_vpn args || return 1
  T_REMOTE="${CONF[remote]:-}"
  [[ "$T_REMOTE" =~ $REMOTE_RE ]] || { LOAD_ERR="$file: remote must be an ssh host alias"; return 1; }
  read -ra T_SUBNETS <<< "${CONF[subnets]:-}"
  read -ra T_EXCLUDE <<< "${CONF[exclude]:-}"
  read -ra T_ARGS <<< "${CONF[args]:-}"
  for tok in "${T_SUBNETS[@]}" "${T_EXCLUDE[@]}"; do
    [[ "$tok" =~ $SUBNET_RE && "$tok" != -* ]] || { LOAD_ERR="$file: invalid subnet '$tok'"; return 1; }
  done
  T_DNS="${CONF[dns]:-off}" T_AUTO_NETS="${CONF[auto_nets]:-no}"
  T_NEEDS_VPN="${CONF[needs_vpn]:-$([[ -n "$V_TYPE" ]] && echo yes || echo no)}"
  [[ "$T_DNS" == on || "$T_DNS" == off ]] || { LOAD_ERR="$file: dns must be on or off"; return 1; }
  [[ "$T_AUTO_NETS" == yes || "$T_AUTO_NETS" == no ]] || { LOAD_ERR="$file: auto_nets must be yes or no"; return 1; }
  [[ "$T_NEEDS_VPN" == yes || "$T_NEEDS_VPN" == no ]] || { LOAD_ERR="$file: needs_vpn must be yes or no"; return 1; }
  if [[ "$T_NEEDS_VPN" == yes && -z "$V_TYPE" ]]; then
    LOAD_ERR="$file: needs_vpn=yes but client '$C_NAME' has no usable vpn.conf"
    return 1
  fi
  if (( ${#T_SUBNETS[@]} == 0 )) && [[ "$T_AUTO_NETS" == no ]]; then
    LOAD_ERR="$file: subnets is empty (set subnets= or auto_nets=yes)"
    return 1
  fi
}

split_target() {
  TGT_CLIENT="${1%%/*}" TGT_TUNNEL=""
  [[ "$1" == */* ]] && TGT_TUNNEL="${1#*/}"
  [[ "$TGT_CLIENT" =~ $NAME_RE ]] || usage_die "invalid client name '$TGT_CLIENT'"
  if [[ "$1" == */* && ! "$TGT_TUNNEL" =~ $NAME_RE ]]; then
    usage_die "invalid tunnel name '$TGT_TUNNEL'"
  fi
}

build_vpn_cmd() {
  case "$V_TYPE" in
    openfortivpn) VPN_CMD=(openfortivpn -c "$V_CONFIG" "${V_ARGS[@]}") ;;
    openvpn) VPN_CMD=(openvpn --cd "${V_CONFIG%/*}" --config "$V_CONFIG" "${V_ARGS[@]}") ;;
  esac
}

# $1=bg makes ssh non-interactive, a background ssh must not read the VPN terminal
build_sshuttle_cmd() {
  local x
  SSHUTTLE_CMD=(sshuttle -r "$T_REMOTE")
  [[ "$T_DNS" == on ]] && SSHUTTLE_CMD+=(--dns)
  [[ "$T_AUTO_NETS" == yes ]] && SSHUTTLE_CMD+=(-N)
  for x in "${T_EXCLUDE[@]}"; do SSHUTTLE_CMD+=(-x "$x"); done
  if [[ "${1:-}" == bg && " ${T_ARGS[*]} " != *" -e "* && " ${T_ARGS[*]} " != *" --ssh-cmd"* ]]; then
    SSHUTTLE_CMD+=(-e "ssh -o BatchMode=yes")
  fi
  SSHUTTLE_CMD+=("${T_ARGS[@]}" "${T_SUBNETS[@]}")
}

check_secret_perms() {
  local mode
  mode="$(stat -c %a "$V_CONFIG" 2>/dev/null)" || return 0
  (( 8#$mode & 8#077 )) && warn "$V_CONFIG is accessible by others (mode $mode), run: chmod 600 '$V_CONFIG'"
  return 0
}

# --- Processes -------------------------------------------------

proc_start() {
  local stat
  local -a f
  [[ "$1" =~ ^[0-9]+$ ]] || return 1
  { read -r stat < "/proc/$1/stat"; } 2>/dev/null || return 1
  read -ra f <<< "${stat##*) }"
  echo "${f[19]}"
}

proc_alive() { [[ -n "${2:-}" && "$(proc_start "$1")" == "$2" ]]; }

proc_epoch() {
  local ticks btime
  ticks="$(proc_start "$1")" || return 1
  btime="$(awk '$1 == "btime" { print $2 }' /proc/stat)"
  echo $(( btime + ticks / $(getconf CLK_TCK) ))
}

scan_procs() {
  local d stat pid
  P_PPID=() P_COMM=()
  for d in /proc/[0-9]*; do
    { read -r stat < "$d/stat"; } 2>/dev/null || continue
    pid="${d#/proc/}"
    P_COMM[$pid]="${stat#*(}"
    P_COMM[$pid]="${P_COMM[$pid]%)*}"
    read -r _ "P_PPID[$pid]" _ <<< "${stat##*) }"
  done
}

child_of() {
  local pid
  [[ -n "$1" ]] || return 1
  for pid in "${!P_PPID[@]}"; do
    [[ "${P_PPID[$pid]}" == "$1" && "${P_COMM[$pid]}" == "$2" ]] && { echo "$pid"; return 0; }
  done
  return 1
}

find_descendant() {
  local queue=("$1") cur pid
  while (( ${#queue[@]} )); do
    cur="${queue[0]}"
    queue=("${queue[@]:1}")
    for pid in "${!P_PPID[@]}"; do
      [[ "${P_PPID[$pid]}" == "$cur" ]] || continue
      [[ "${P_COMM[$pid]}" =~ $2 ]] && { echo "$pid"; return 0; }
      queue+=("$pid")
    done
  done
  return 1
}

read_argv() {
  ARGV=()
  { mapfile -d '' -t ARGV < "/proc/$1/cmdline"; } 2>/dev/null
}

norm_words() {
  (( $# )) || return 0
  printf '%s\n' "$@" | sort -u | paste -sd ' '
}

# Print the resolved config path from the openfortivpn/openvpn argv in ARGV
argv_vpn_config() {
  local i start=0 a cfg="" dir=""
  for ((i = 0; i < ${#ARGV[@]}; i++)); do
    [[ "${ARGV[i]##*/}" == "${P_COMM[$1]}" ]] && { start=$i; break; }
  done
  for ((i = start + 1; i < ${#ARGV[@]}; i++)); do
    a="${ARGV[i]}"
    case "$a" in
      -c|--config) cfg="${ARGV[i + 1]:-}"; i=$((i + 1)) ;;
      --config=*) cfg="${a#*=}" ;;
      -c?*) cfg="${a#-c}" ;;
      --cd) dir="${ARGV[i + 1]:-}"; i=$((i + 1)) ;;
      *.ovpn|*.conf) [[ -z "$cfg" && "${P_COMM[$1]}" == openvpn ]] && cfg="$a" ;;
    esac
  done
  [[ -n "$cfg" ]] || return 0
  if [[ "$cfg" != /* ]]; then
    [[ -n "$dir" ]] || dir="$(readlink "/proc/$1/cwd" 2>/dev/null)" || return 0
    cfg="$dir/$cfg"
  fi
  realpath -m "$cfg"
}

# Set S_REMOTE and S_SUBNETS from a sshuttle client argv in ARGV
parse_sshuttle_argv() {
  local i start=-1 a
  S_REMOTE="" S_SUBNETS=()
  for ((i = 0; i < ${#ARGV[@]}; i++)); do
    [[ "${ARGV[i]##*/}" == sshuttle ]] && { start=$i; break; }
  done
  (( start >= 0 )) || return 1
  for ((i = start + 1; i < ${#ARGV[@]}; i++)); do
    a="${ARGV[i]}"
    case "$a" in
      --firewall|--hostwatch|--server) return 1 ;;
      -r|--remote) S_REMOTE="${ARGV[i + 1]:-}"; i=$((i + 1)) ;;
      --remote=*) S_REMOTE="${a#*=}" ;;
      -r?*) S_REMOTE="${a#-r}" ;;
      -x|--exclude|-X|--exclude-from|-e|--ssh-cmd|-l|--listen|--method|--python|--to-ns|--ns-hosts|\
      --seed-hosts|--pidfile|--user|--group|-s|--subnets|--latency-buffer-size|--tmark) i=$((i + 1)) ;;
      -*) ;;
      *) S_SUBNETS+=("$a") ;;
    esac
  done
}

scan_external() {
  local pid
  EXT_VPNS=() EXT_TUNNELS=() EXT_TYPE=() EXT_CONFIG=() EXT_REMOTE=() EXT_SUBNETS=()
  for pid in "${!P_COMM[@]}"; do
    case "${P_COMM[$pid]}" in
      openfortivpn|openvpn)
        read_argv "$pid"
        EXT_VPNS+=("$pid")
        EXT_TYPE[$pid]="${P_COMM[$pid]}"
        EXT_CONFIG[$pid]="$(argv_vpn_config "$pid")"
        ;;
      sshuttle|python*)
        read_argv "$pid"
        parse_sshuttle_argv || continue
        EXT_TUNNELS+=("$pid")
        EXT_REMOTE[$pid]="$S_REMOTE"
        EXT_SUBNETS[$pid]="$(norm_words "${S_SUBNETS[@]}")"
        ;;
    esac
  done
}

# --- Network ---------------------------------------------------

# Set R_IP to the IPv4 address the ssh alias connects to
resolve_remote() {
  local host ip
  R_IP="${RESOLVED[$1]:-}"
  [[ -n "$R_IP" ]] && return 0
  host="${1#*@}"
  host="${host%%:*}"
  ip="$(ssh -G "$host" 2>/dev/null | awk '$1 == "hostname" { print $2; exit }')"
  [[ -n "$ip" ]] || ip="$host"
  [[ "$ip" =~ ^[0-9]+(\.[0-9]+){3}$ ]] || ip="$(getent ahostsv4 "$ip" 2>/dev/null | awk 'NR == 1 { print $1 }')"
  R_IP="$ip"
  [[ -n "$ip" ]] || return 1
  RESOLVED[$1]="$ip"
}

route_dev() { ip -j route get "$1" 2>/dev/null | jq -r '.[0].dev // empty' 2>/dev/null; }

# IFACES[name]="up|down <ipv4>" for ppp*/tun*/wg* interfaces
scan_ifaces() {
  local name state addr
  IFACES=()
  while IFS=$'\x1f' read -r name state addr; do
    [[ -n "$name" ]] && IFACES[$name]="$state $addr"
  done < <(ip -j addr show 2>/dev/null | jq -r --arg re "$VPN_IFACE_RE" '.[] | select(.ifname | test($re))
    | [.ifname, (if any(.flags[]?; . == "UP") then "up" else "down" end),
       ([.addr_info[]? | select(.family == "inet") | .local][0] // "")] | join("\u001f")' 2>/dev/null)
}

iface_ready() { [[ "${IFACES[$1]:-}" == "up "?* ]]; }

scan_all() { scan_procs; scan_external; scan_ifaces; }

# --- State -----------------------------------------------------

write_state() {
  local file="$1" tmp
  shift
  tmp="$(mktemp "$file.XXXXXX")" || return 1
  printf '%s\n' "$@" > "$tmp" && mv -f "$tmp" "$file"
}

read_state() { parse_conf "$1" "${STATE_KEYS[@]}"; }

# Load a state file into CONF; stale or corrupt files are removed
state_alive() {
  [[ -f "$1" ]] || return 1
  if read_state "$1"; then
    if [[ -n "${CONF[pid]:-}" ]]; then
      proc_alive "${CONF[pid]}" "${CONF[pid_start]:-}" && return 0
    else
      proc_alive "${CONF[wrapper]:-}" "${CONF[wrapper_start]:-}" && return 0
    fi
  fi
  rm -f "$1"
  return 1
}

state_pid() {
  if [[ -n "${CONF[pid]:-}" ]]; then
    echo "${CONF[pid]}"
  else
    child_of "${CONF[wrapper]:-}" "$1"
  fi
}

# --- Status ----------------------------------------------------

# Set VS_* for the loaded client (needs scan_all)
vpn_status() {
  local pid sudo_pid
  VS_STATE=down VS_MANAGED=false VS_PID="" VS_IFACE="" VS_SINCE=""
  if state_alive "$STATE_DIR/$C_NAME.vpn"; then
    VS_MANAGED=true VS_STATE=connecting VS_SINCE="${CONF[start]:-}" VS_IFACE="${CONF[iface]:-}"
    if sudo_pid="$(child_of "${CONF[wrapper]}" sudo)"; then
      VS_PID="$(find_descendant "$sudo_pid" '^(openfortivpn|openvpn)$')" || VS_PID="$sudo_pid"
    fi
    [[ -n "$VS_IFACE" ]] && iface_ready "$VS_IFACE" && VS_STATE=up
  fi
  for pid in "${EXT_VPNS[@]}"; do
    [[ "${EXT_TYPE[$pid]}" == "$V_TYPE" && "${EXT_CONFIG[$pid]}" == "$V_CONFIG" ]] || continue
    CLAIMED[$pid]=1
    if [[ "$VS_STATE" == down ]]; then
      VS_STATE=up VS_PID="$pid" VS_SINCE="$(proc_epoch "$pid")"
    fi
  done
}

# Set TS_* for the loaded tunnel (needs scan_all)
tunnel_status() {
  local pid subnets
  TS_STATE=down TS_MANAGED=false TS_PID="" TS_SINCE="" TS_LOG="" TS_IP="" TS_DEV="" TS_VIA=false
  if state_alive "$STATE_DIR/$C_NAME-$T_NAME.tunnel"; then
    TS_STATE=up TS_MANAGED=true TS_SINCE="${CONF[start]:-}" TS_LOG="${CONF[log]:-}"
    TS_PID="$(state_pid sshuttle)"
    [[ -n "$TS_PID" ]] && CLAIMED[$TS_PID]=1
  fi
  subnets="$(norm_words "${T_SUBNETS[@]}")"
  for pid in "${EXT_TUNNELS[@]}"; do
    [[ "${EXT_REMOTE[$pid]}" == "$T_REMOTE" && "${EXT_SUBNETS[$pid]}" == "$subnets" ]] || continue
    CLAIMED[$pid]=1
    if [[ "$TS_STATE" == down ]]; then
      TS_STATE=up TS_PID="$pid" TS_SINCE="$(proc_epoch "$pid")"
    fi
  done
  if resolve_remote "$T_REMOTE"; then
    TS_IP="$R_IP"
    TS_DEV="$(route_dev "$R_IP")"
    [[ "$TS_DEV" =~ $VPN_IFACE_RE ]] && TS_VIA=true
  fi
}

json_array() {
  if (( $# )); then printf '%s\n' "$@" | jq -cs .; else echo '[]'; fi
}

status_json() {
  local c t pid now vpn
  local -a names tnames clients=() tunnels=() uvpns=() utunnels=() ifaces=()
  local -A remote_client=()
  scan_all
  mapfile -t names < <(list_clients)
  for c in "${names[@]}"; do
    if ! load_client "$c"; then
      clients+=("$(jq -cn --arg name "$c" --arg err "$LOAD_ERR" \
        '{name: $name, label: $name, color: null, error: $err, vpn: null, tunnels: []}')")
      continue
    fi
    vpn=null
    if [[ -n "$V_TYPE" ]]; then
      vpn_status
      vpn="$(jq -cn --arg type "$V_TYPE" --arg state "$VS_STATE" --argjson managed "$VS_MANAGED" \
        --arg pid "$VS_PID" --arg iface "$VS_IFACE" --arg since "$VS_SINCE" --arg config "$V_CONFIG" "$JQ_DEFS"'
        {type: $type, state: $state, up: ($state == "up"), managed: $managed, pid: ($pid | num),
         iface: ($iface | str), since: ($since | num), config: $config}')"
    fi
    tunnels=()
    mapfile -t tnames < <(list_tunnels)
    for t in "${tnames[@]}"; do
      if ! load_tunnel "$t"; then
        tunnels+=("$(jq -cn --arg name "$t" --arg id "$C_NAME/$t" --arg err "$LOAD_ERR" '
          {name: $name, id: $id, error: $err, state: "down", up: false, managed: false, pid: null, since: null,
           remote: null, subnets: [], exclude: [], dns: false, auto_nets: false, needs_vpn: false,
           route: null, log: null}')")
        continue
      fi
      remote_client[$T_REMOTE]="$C_NAME"
      tunnel_status
      tunnels+=("$(jq -cn --arg name "$T_NAME" --arg id "$C_NAME/$T_NAME" --arg state "$TS_STATE" \
        --argjson managed "$TS_MANAGED" --arg pid "$TS_PID" --arg since "$TS_SINCE" --arg remote "$T_REMOTE" \
        --arg subnets "${T_SUBNETS[*]}" --arg exclude "${T_EXCLUDE[*]}" --arg dns "$T_DNS" \
        --arg auto "$T_AUTO_NETS" --arg needs "$T_NEEDS_VPN" --arg ip "$TS_IP" --arg dev "$TS_DEV" \
        --argjson via "$TS_VIA" --arg log "$TS_LOG" "$JQ_DEFS"'
        {name: $name, id: $id, error: null, state: $state, up: ($state == "up"), managed: $managed,
         pid: ($pid | num), since: ($since | num), remote: $remote, subnets: ($subnets | words),
         exclude: ($exclude | words), dns: ($dns == "on"), auto_nets: ($auto == "yes"),
         needs_vpn: ($needs == "yes"), route: {ip: ($ip | str), dev: ($dev | str), via_vpn: $via},
         log: ($log | str)}')")
    done
    clients+=("$(jq -cn --arg name "$C_NAME" --arg label "$C_LABEL" --arg color "$C_COLOR" \
      --argjson vpn "$vpn" --argjson tunnels "$(json_array "${tunnels[@]}")" "$JQ_DEFS"'
      {name: $name, label: $label, color: ($color | str), error: null, vpn: $vpn, tunnels: $tunnels}')")
  done
  for pid in "${EXT_VPNS[@]}"; do
    [[ -n "${CLAIMED[$pid]:-}" ]] && continue
    uvpns+=("$(jq -cn --arg pid "$pid" --arg type "${EXT_TYPE[$pid]}" --arg config "${EXT_CONFIG[$pid]}" \
      --arg since "$(proc_epoch "$pid")" "$JQ_DEFS"'
      {pid: ($pid | num), type: $type, config: ($config | str), since: ($since | num)}')")
  done
  for pid in "${EXT_TUNNELS[@]}"; do
    [[ -n "${CLAIMED[$pid]:-}" ]] && continue
    c=""
    [[ -n "${EXT_REMOTE[$pid]}" ]] && c="${remote_client[${EXT_REMOTE[$pid]}]:-}"
    utunnels+=("$(jq -cn --arg pid "$pid" --arg remote "${EXT_REMOTE[$pid]}" --arg subnets "${EXT_SUBNETS[$pid]}" \
      --arg client "$c" --arg since "$(proc_epoch "$pid")" "$JQ_DEFS"'
      {pid: ($pid | num), remote: ($remote | str), subnets: ($subnets | words), client: ($client | str),
       since: ($since | num)}')")
  done
  for c in "${!IFACES[@]}"; do
    ifaces+=("$(jq -cn --arg name "$c" --arg info "${IFACES[$c]}" "$JQ_DEFS"'
      ($info | split(" ")) as $f | {name: $name, up: ($f[0] == "up"), addr: (($f[1] // "") | str)}')")
  done
  printf -v now '%(%s)T' -1
  jq -n --argjson clients "$(json_array "${clients[@]}")" --argjson vpns "$(json_array "${uvpns[@]}")" \
    --argjson tunnels "$(json_array "${utunnels[@]}")" --argjson ifaces "$(json_array "${ifaces[@]}")" \
    --argjson now "$now" '
    {version: 1, generated: $now, clients: $clients,
     unmanaged: {vpns: ($vpns | sort_by(.pid)), tunnels: ($tunnels | sort_by(.pid))},
     interfaces: ($ifaces | sort_by(.name))}'
}

fmt_since() {
  local now
  [[ -n "$1" ]] || return 0
  printf -v now '%(%s)T' -1
  if (( now - $1 < 86400 )); then printf ' since %(%H:%M)T' "$1"; else printf ' since %(%b %d %H:%M)T' "$1"; fi
}

cmd_status() {
  local json kind a b c d e f g h
  case "${1:-}" in
    --json) status_json; return ;;
    "") ;;
    *) usage_die "unknown status option '$1'" ;;
  esac
  json="$(status_json)" || die "failed to collect status"
  [[ "$(jq '.clients | length' <<< "$json")" != 0 ]] || echo "No clients in $VPN_DIR"
  while IFS=$'\x1f' read -r kind a b c d e f g h; do
    case "$kind" in
      C)
        if [[ -n "$h" ]]; then
          printf '%-24s error: %s\n' "$a" "$h"
        elif [[ "$d" == none ]]; then
          printf '%-24s %-13s %s\n' "$a" "-" "no VPN"
        else
          printf '%-24s %-13s %s%s%s%s\n' "$a" "$c" "$d" "${e:+ $e}" "$(fmt_since "$f")" "${g:+ ($g)}"
        fi
        ;;
      T)
        if [[ -n "$h" ]]; then
          printf '  %-22s error: %s\n' "${a#*/}" "$h"
        else
          printf '  %-22s %-13s %s%s  %s -> %s%s\n' "${a#*/}" "$b" "$e" "${g:+ ($g)}" "$c" "$d" "$(fmt_since "$f")"
        fi
        ;;
      V) printf 'unmanaged %-14s pid %s  %s%s\n' "$b" "$a" "$c" "$(fmt_since "$d")" ;;
      U) printf 'unmanaged %-14s pid %s  %s -> %s%s%s\n' "sshuttle" "$a" "$b" "$c" "${d:+ (client $d?)}" "$(fmt_since "$e")" ;;
      I) printf 'interface %-14s %s%s\n' "$a" "$b" "${c:+ $c}" ;;
    esac
  done < <(jq -r '
    def row: map(if . == null then "" else tostring end) | join("\u001f");
    (.clients[] | (["C", .name, .label, .vpn.type, (.vpn.state // "none"), .vpn.iface, .vpn.since,
        (if .vpn != null and .vpn.managed == false and .vpn.up then "external" else null end), .error] | row),
      (.tunnels[] | ["T", .id, .state,
        (.remote), (.subnets | join(" ")),
        (if .route == null then "" elif .route.ip == null then "unresolved"
         elif .route.via_vpn then "via " + .route.dev else "direct" + (if .route.dev then " (" + .route.dev + ")" else "" end) end),
        .since, (if .up and (.managed | not) then "external" else null end), .error] | row)),
    (.unmanaged.vpns[] | ["V", .pid, .type, (.config // "unknown config"), .since] | row),
    (.unmanaged.tunnels[] | ["U", .pid, .remote, (.subnets | join(" ")), .client, .since] | row),
    (.interfaces[] | ["I", .name, (if .up then "up" else "down" end), .addr] | row)' <<< "$json")
}

cmd_list() {
  local c t
  local -a names tnames
  mapfile -t names < <(list_clients)
  (( ${#names[@]} )) || { echo "No clients in $VPN_DIR" >&2; return 1; }
  for c in "${names[@]}"; do
    if ! load_client "$c"; then
      printf '%-28s error: %s\n' "$c" "$LOAD_ERR"
      continue
    fi
    printf '%-28s %s\n' "$c" "${V_TYPE:-no VPN}$([[ "$C_LABEL" != "$c" ]] && echo "  ($C_LABEL)")"
    mapfile -t tnames < <(list_tunnels)
    for t in "${tnames[@]}"; do
      if load_tunnel "$t"; then
        printf '%-28s %s\n' "$c/$t" "sshuttle $T_REMOTE ${T_SUBNETS[*]}"
      else
        printf '%-28s error: %s\n' "$c/$t" "$LOAD_ERR"
      fi
    done
  done
}

# --- Up --------------------------------------------------------

# Background helper of run_vpn: record the interface, then start the tunnel once routed
vpn_watch() {
  local tunnel="$1" before sudo_pid="" vpn_pid="" deadline=0 iface="" dev="" now name
  trap 'watch_abort' TERM
  scan_ifaces
  before=" ${!IFACES[*]} "
  [[ -n "$tunnel" ]] && resolve_remote "$T_REMOTE"
  while [[ -d "/proc/$$" ]]; do
    printf -v now '%(%s)T' -1
    scan_procs
    if [[ -z "$sudo_pid" ]]; then
      sudo_pid="$(child_of "$$" sudo)"
    elif [[ -z "${P_COMM[$sudo_pid]:-}" ]]; then
      exit 0
    elif [[ -z "$vpn_pid" ]]; then
      vpn_pid="$(find_descendant "$sudo_pid" '^(openfortivpn|openvpn)$')" && deadline=$((now + VPN_TIMEOUT))
    else
      if [[ -z "$iface" ]]; then
        scan_ifaces
        for name in "${!IFACES[@]}"; do
          [[ "$before" != *" $name "* ]] && iface_ready "$name" && iface="$name" && save_vpn_state "$iface" && break
        done
      fi
      if [[ -n "$tunnel" ]]; then
        [[ -n "$R_IP" ]] || resolve_remote "$T_REMOTE"
        if [[ -n "$R_IP" ]]; then
          dev="$(route_dev "$R_IP")"
          if [[ "$dev" =~ $VPN_IFACE_RE ]]; then
            [[ -n "$iface" ]] || save_vpn_state "$dev"
            start_tunnel_bg "$dev"
            exit
          fi
        elif [[ -n "$iface" ]]; then
          start_tunnel_bg "$iface"
          exit
        fi
      elif [[ -n "$iface" ]]; then
        exit 0
      fi
      if (( now >= deadline )); then
        if [[ -n "$tunnel" ]]; then
          warn "timed out after ${VPN_TIMEOUT}s waiting for $T_REMOTE${R_IP:+ ($R_IP)} to route through a VPN interface${dev:+ (it goes via $dev)}; tunnel '$C_NAME/$tunnel' not started, run 'vpn up $C_NAME/$tunnel' once the VPN is up"
        else
          warn "no new VPN interface after ${VPN_TIMEOUT}s, status will not show it"
        fi
        exit 1
      fi
    fi
    sleep 0.5
  done
}

watch_abort() {
  [[ "${WATCH_LAUNCHING:-0}" == 1 ]] && kill -TERM "$!" 2>/dev/null
  exit 0
}

save_vpn_state() {
  write_state "$UP_STATE" "client=$C_NAME" "wrapper=$$" "wrapper_start=$UP_WSTART" "start=$UP_START" \
    "type=$V_TYPE" "config=$V_CONFIG" "iface=$1"
}

start_tunnel_bg() {
  local tstate="$STATE_DIR/$C_NAME-$T_NAME.tunnel" log="$STATE_DIR/$C_NAME-$T_NAME.log" pid start
  if ! sudo -n -v 2>/dev/null; then
    warn "sudo credentials are not cached, so sshuttle cannot ask for them in the background; run 'vpn up $C_NAME/$T_NAME' in another terminal"
    return 1
  fi
  build_sshuttle_cmd bg
  printf -v start '%(%s)T' -1
  printf '%(%F %T)T vpn: %s\n' -1 "${SSHUTTLE_CMD[*]}" >> "$log"
  WATCH_LAUNCHING=1
  "${SSHUTTLE_CMD[@]}" >> "$log" 2>&1 &
  pid=$!
  write_state "$tstate" "client=$C_NAME" "tunnel=$T_NAME" "pid=$pid" "pid_start=$(proc_start "$pid")" \
    "start=$start" "remote=$T_REMOTE" "subnets=${T_SUBNETS[*]}" "owner=$$" "log=$log"
  WATCH_LAUNCHING=0
  warn "VPN is up on $1, tunnel '$C_NAME/$T_NAME' started (pid $pid, log $log)"
}

up_cleanup() {
  local f
  trap - EXIT INT TERM HUP
  if [[ -n "${UP_WATCH:-}" ]]; then
    kill -TERM "$UP_WATCH" 2>/dev/null
    wait "$UP_WATCH" 2>/dev/null
  fi
  for f in "$STATE_DIR"/*.tunnel; do
    [[ -f "$f" ]] && read_state "$f" && [[ "${CONF[owner]:-}" == "$$" ]] || continue
    stop_state_file "$f" && warn "stopped tunnel '${CONF[client]:-?}/${CONF[tunnel]:-?}'"
  done
  # sudo runs the VPN in its own session, so a closed terminal only reaches this script
  if [[ -n "${UP_SUDO:-}" ]] && kill -0 "$UP_SUDO" 2>/dev/null; then
    kill -TERM "$UP_SUDO" 2>/dev/null
    wait "$UP_SUDO" 2>/dev/null
    warn "stopped VPN '$C_NAME'"
  fi
  if [[ -f "$UP_STATE" ]] && read_state "$UP_STATE" && [[ "${CONF[wrapper]:-}" == "$$" ]]; then
    rm -f "$UP_STATE"
  fi
}

# Run the loaded client's VPN in the foreground; $1 names a tunnel to start once it is up
run_vpn() {
  local tunnel="$1" rc
  build_vpn_cmd
  need "${VPN_CMD[0]}"
  [[ -z "$tunnel" ]] || need sshuttle
  check_secret_perms
  UP_STATE="$STATE_DIR/$C_NAME.vpn" UP_WSTART="$(proc_start $$)" UP_WATCH="" UP_SUDO=""
  printf -v UP_START '%(%s)T' -1
  save_vpn_state "" || die "cannot write $UP_STATE"
  trap up_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  vpn_watch "$tunnel" &
  UP_WATCH=$!
  warn "starting $V_TYPE for '$C_LABEL'${tunnel:+, tunnel '$tunnel' starts once it is up} (Ctrl-C to stop)"
  # Background + wait so traps fire; <&0 keeps the prompts on the terminal, env undoes the SIGINT ignore of jobs
  env --default-signal=INT,QUIT sudo "${VPN_CMD[@]}" <&0 &
  UP_SUDO=$!
  wait "$UP_SUDO"
  rc=$?
  UP_SUDO=""
  exit "$rc"
}

tunnel_cleanup() {
  trap - EXIT INT TERM HUP
  if [[ -f "$UP_TSTATE" ]] && read_state "$UP_TSTATE" && [[ "${CONF[wrapper]:-}" == "$$" ]]; then
    rm -f "$UP_TSTATE"
  fi
}

run_tunnel_fg() {
  local rc start
  need sshuttle
  build_sshuttle_cmd
  UP_TSTATE="$STATE_DIR/$C_NAME-$T_NAME.tunnel"
  printf -v start '%(%s)T' -1
  write_state "$UP_TSTATE" "client=$C_NAME" "tunnel=$T_NAME" "wrapper=$$" "wrapper_start=$(proc_start $$)" \
    "start=$start" "remote=$T_REMOTE" "subnets=${T_SUBNETS[*]}" || die "cannot write $UP_TSTATE"
  trap tunnel_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  warn "starting tunnel '$C_NAME/$T_NAME' via $T_REMOTE (Ctrl-C to stop)"
  "${SSHUTTLE_CMD[@]}"
  rc=$?
  exit "$rc"
}

cmd_up() {
  split_target "$1"
  load_client "$TGT_CLIENT" || die "$LOAD_ERR"
  mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR" || die "cannot create $STATE_DIR"
  scan_all
  if [[ -z "$TGT_TUNNEL" ]]; then
    [[ -n "$V_TYPE" ]] || die "client '$C_NAME' has no vpn.conf"
    vpn_status
    [[ "$VS_STATE" == down ]] || die "VPN for '$C_NAME' is already $VS_STATE${VS_PID:+ (pid $VS_PID)}"
    run_vpn ""
  fi
  load_tunnel "$TGT_TUNNEL" || die "$LOAD_ERR"
  tunnel_status
  [[ "$TS_STATE" == down ]] || die "tunnel '$C_NAME/$T_NAME' is already up${TS_PID:+ (pid $TS_PID)}"
  if [[ "$T_NEEDS_VPN" == yes && "$TS_VIA" != true ]]; then
    vpn_status
    case "$VS_STATE" in
      down) run_vpn "$T_NAME" ;;
      connecting) die "VPN for '$C_NAME' is still connecting, run this again once it is up" ;;
      up) warn "VPN for '$C_NAME' is up but $T_REMOTE${TS_IP:+ ($TS_IP)} does not route through it${TS_DEV:+ (goes via $TS_DEV)}, starting sshuttle anyway" ;;
    esac
  fi
  run_tunnel_fg
}

cmd_pick() {
  local sel self
  need fzf
  self="$(realpath "$0")"
  sel="$(cmd_list | fzf --cycle --layout=reverse --header="Select VPN or tunnel" --bind "tab:down,btab:up" \
    --preview "'$self' __preview {1}" --preview-window=down,55%,wrap)"
  if [[ -z "$sel" ]]; then
    echo "Nothing selected."
    exit 0
  fi
  cmd_up "${sel%% *}"
}

# --- Preview ---------------------------------------------------

field() { [[ -n "$2" ]] && printf '  %-11s %s\n' "$1" "$2"; return 0; }

tilde() { echo "${1//"$HOME"/\~}"; }

# Gateway host:port from the VPN config, never its credentials
vpn_gateway() {
  case "$V_TYPE" in
    openfortivpn)
      awk -F'[[:space:]]*=[[:space:]]*' '{ sub(/^[[:space:]]+/, "") }
        $1 == "host" { h = $2 } $1 == "port" { p = $2 } END { if (h != "") print h (p != "" ? ":" p : "") }' "$V_CONFIG"
      ;;
    openvpn) awk '$1 == "remote" { printf "%s%s%s", (n++ ? ", " : ""), $2, ($3 != "" ? ":" $3 : "") } END { if (n) print "" }' "$V_CONFIG" ;;
  esac
}

vpn_state_line() {
  local addr=""
  [[ -n "$VS_IFACE" ]] && addr="${IFACES[$VS_IFACE]:-}" && addr="${addr#* }"
  echo "$VS_STATE${VS_IFACE:+ on $VS_IFACE}${addr:+ ($addr)}$(fmt_since "$VS_SINCE")${VS_PID:+, pid $VS_PID}"
}

show_client() {
  local t
  local -a tnames
  echo "$C_LABEL ($C_NAME)"
  if [[ -z "$V_TYPE" ]]; then
    field vpn "none, sshuttle tunnels only"
  else
    vpn_status
    build_vpn_cmd
    field vpn "$V_TYPE"
    field gateway "$(vpn_gateway)"
    field state "$(vpn_state_line)"
    field config "$(tilde "$V_CONFIG")"
    field command "$(tilde "sudo ${VPN_CMD[*]}")"
  fi
  mapfile -t tnames < <(list_tunnels)
  (( ${#tnames[@]} )) || return 0
  echo
  echo "Tunnels"
  for t in "${tnames[@]}"; do
    if load_tunnel "$t"; then
      tunnel_status
      printf '  %-11s %-5s %s\n' "$t" "$TS_STATE" "sshuttle $T_REMOTE ${T_SUBNETS[*]:-(auto)}"
    else
      printf '  %-11s error: %s\n' "$t" "$LOAD_ERR"
    fi
  done
}

show_tunnel() {
  local host route needs
  tunnel_status
  build_sshuttle_cmd
  echo "$C_LABEL › $T_NAME"
  field state "$TS_STATE$(fmt_since "$TS_SINCE")${TS_PID:+, pid $TS_PID}$([[ "$TS_STATE" == up && "$TS_MANAGED" == false ]] && echo ', started outside vpn')"
  field remote "$T_REMOTE"
  host="$T_REMOTE"
  [[ "$host" =~ :[0-9]+$ ]] && host="${host%:*}"
  while read -r key value; do
    field "  $key" "$(tilde "$value")"
  done < <(ssh -G "$host" 2>/dev/null | awk '$1 ~ /^(hostname|user|port|proxyjump)$/ { print }
    $1 == "identityfile" && !id++ { print "key", $2 }')
  if [[ -z "$TS_IP" ]]; then
    route="unresolved"
  elif [[ "$TS_VIA" == true ]]; then
    route="$TS_IP via $TS_DEV (VPN)"
  else
    route="$TS_IP direct${TS_DEV:+ via $TS_DEV}"
  fi
  field route "$route"
  field subnets "${T_SUBNETS[*]:-}$([[ "$T_AUTO_NETS" == yes ]] && echo "${T_SUBNETS[*]:+ + }auto (-N)")"
  field exclude "${T_EXCLUDE[*]:-}"
  field dns "$([[ "$T_DNS" == on ]] && echo 'through the tunnel (--dns)' || echo 'local')"
  if [[ "$T_NEEDS_VPN" == yes ]]; then
    vpn_status
    needs="yes, $V_TYPE $(vpn_state_line)"
  else
    needs="no"
  fi
  field needs_vpn "$needs"
  field command "${SSHUTTLE_CMD[*]}"
  if [[ -n "$TS_LOG" && -s "$TS_LOG" ]]; then
    field log "$(tilde "$TS_LOG")"
    echo
    tail -n 5 "$TS_LOG" | sed 's/^/  /'
  fi
}

# fzf preview of the picker, not a user command
cmd_preview() {
  split_target "$1"
  load_client "$TGT_CLIENT" || die "$LOAD_ERR"
  scan_all
  if [[ -n "$TGT_TUNNEL" ]]; then
    load_tunnel "$TGT_TUNNEL" || die "$LOAD_ERR"
    show_tunnel
  else
    show_client
  fi
}

# --- Down ------------------------------------------------------

# Send TERM (through sudo when $3=sudo), escalating to KILL after 10s
terminate() {
  local pid="$1" start="$2" i
  local -a pre=()
  [[ "${3:-}" == sudo ]] && pre=(sudo)
  "${pre[@]}" kill -TERM "$pid" 2>/dev/null || { proc_alive "$pid" "$start" || return 0; return 1; }
  for ((i = 0; i < 50; i++)); do
    proc_alive "$pid" "$start" || return 0
    sleep 0.2
  done
  warn "pid $pid did not exit after 10s, sending KILL"
  "${pre[@]}" kill -KILL "$pid" 2>/dev/null
}

wait_gone() {
  local i
  [[ -n "$1" ]] || return 0
  for ((i = 0; i < 50; i++)); do
    proc_alive "$1" "$2" || return 0
    sleep 0.2
  done
  return 1
}

# Stop whatever a live state file points at; fails when nothing was running
stop_state_file() {
  local file="$1" pid wrapper wstart
  state_alive "$file" || return 1
  wrapper="${CONF[wrapper]:-}" wstart="${CONF[wrapper_start]:-}"
  scan_procs
  case "$file" in
    *.vpn)
      if pid="$(child_of "$wrapper" sudo)"; then
        terminate "$pid" "$(proc_start "$pid")" sudo || warn "could not stop VPN pid $pid"
      else
        terminate "$wrapper" "$wstart"
      fi
      ;;
    *.tunnel)
      pid="$(state_pid sshuttle)" && terminate "$pid" "$(proc_start "$pid")"
      ;;
  esac
  wait_gone "$wrapper" "$wstart" || warn "wrapper pid $wrapper is still running"
  rm -f "$file"
}

down_tunnel() {
  local t="$1" pid subnets
  if stop_state_file "$STATE_DIR/$C_NAME-$t.tunnel"; then
    echo "vpn: stopped $C_NAME/$t"
    STOPPED=$((STOPPED + 1))
    return 0
  fi
  load_tunnel "$t" || return 0
  scan_procs
  scan_external
  subnets="$(norm_words "${T_SUBNETS[@]}")"
  for pid in "${EXT_TUNNELS[@]}"; do
    [[ "${EXT_REMOTE[$pid]}" == "$T_REMOTE" && "${EXT_SUBNETS[$pid]}" == "$subnets" ]] || continue
    terminate "$pid" "$(proc_start "$pid")" && echo "vpn: stopped $C_NAME/$t (external sshuttle pid $pid)"
    STOPPED=$((STOPPED + 1))
  done
}

down_vpn() {
  local pid
  if stop_state_file "$STATE_DIR/$C_NAME.vpn"; then
    echo "vpn: stopped VPN $C_NAME"
    STOPPED=$((STOPPED + 1))
    return 0
  fi
  [[ -n "$V_TYPE" ]] || return 0
  scan_procs
  scan_external
  for pid in "${EXT_VPNS[@]}"; do
    [[ "${EXT_TYPE[$pid]}" == "$V_TYPE" && "${EXT_CONFIG[$pid]}" == "$V_CONFIG" ]] || continue
    terminate "$pid" "$(proc_start "$pid")" sudo && echo "vpn: stopped VPN $C_NAME (external pid $pid)"
    STOPPED=$((STOPPED + 1))
  done
}

down_client() {
  local t f
  local -a tnames
  load_client "$1" || warn "$LOAD_ERR"
  mapfile -t tnames < <(list_tunnels)
  for t in "${tnames[@]}"; do down_tunnel "$t"; done
  for f in "$STATE_DIR/$1"-*.tunnel; do
    [[ -f "$f" ]] && read_state "$f" && [[ "${CONF[client]:-}" == "$1" ]] || continue
    t="${CONF[tunnel]:-?}"
    stop_state_file "$f" && echo "vpn: stopped $1/$t" && STOPPED=$((STOPPED + 1))
  done
  down_vpn
}

cmd_down() {
  local c f
  local -a names
  if [[ -z "${1:-}" ]]; then
    mapfile -t names < <(list_clients)
    for c in "${names[@]}"; do down_client "$c"; done
    for f in "$STATE_DIR"/*.tunnel "$STATE_DIR"/*.vpn; do
      [[ -f "$f" ]] || continue
      stop_state_file "$f" && echo "vpn: stopped ${f##*/}" && STOPPED=$((STOPPED + 1))
    done
    (( STOPPED )) || echo "vpn: nothing running"
    return 0
  fi
  split_target "$1"
  if [[ -n "$TGT_TUNNEL" ]]; then
    load_client "$TGT_CLIENT" || [[ -d "$VPN_DIR/$TGT_CLIENT" ]] || die "$LOAD_ERR"
    down_tunnel "$TGT_TUNNEL"
  else
    [[ -d "$VPN_DIR/$TGT_CLIENT" || -f "$STATE_DIR/$TGT_CLIENT.vpn" ]] || die "unknown client '$TGT_CLIENT'"
    down_client "$TGT_CLIENT"
  fi
  (( STOPPED )) || echo "vpn: $1 is not running"
}

# --- Edit ------------------------------------------------------

cmd_edit() {
  local path
  local -a editor
  split_target "$1"
  [[ -d "$VPN_DIR/$TGT_CLIENT" ]] || die "unknown client '$TGT_CLIENT' (create $VPN_DIR/$TGT_CLIENT first)"
  path="$VPN_DIR/$TGT_CLIENT"
  if [[ -n "$TGT_TUNNEL" ]]; then
    mkdir -p "$path/tunnels" || die "cannot create $path/tunnels"
    path="$path/tunnels/$TGT_TUNNEL.conf"
  fi
  read -ra editor <<< "${EDITOR:-vi}"
  exec "${editor[@]}" "$path"
}

# --- Main ------------------------------------------------------

main() {
  local cmd="${1:-}"
  (( $# )) && shift
  case "$cmd" in
    -h|--help|help) usage ;;
    "") need jq; cmd_pick ;;
    up) need jq; (( $# == 1 )) || usage_die "usage: vpn up <client>[/<tunnel>]"; cmd_up "$1" ;;
    down) (( $# <= 1 )) || usage_die "usage: vpn down [<client>[/<tunnel>]]"; cmd_down "${1:-}" ;;
    status) need jq; (( $# <= 1 )) || usage_die "usage: vpn status [--json]"; cmd_status "${1:-}" ;;
    list|ls) (( $# == 0 )) || usage_die "usage: vpn list"; cmd_list ;;
    __preview) (( $# == 1 )) || exit 2; cmd_preview "$1" ;;
    edit) (( $# == 1 )) || usage_die "usage: vpn edit <client>[/<tunnel>]"; cmd_edit "$1" ;;
    *) usage_die "unknown command '$cmd'" ;;
  esac
}

main "$@"
