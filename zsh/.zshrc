export ZSH="$HOME/.oh-my-zsh"
export EDITOR=/usr/local/bin/nvim
ZSH_THEME="robbyrussell"


################################################## funtions

#add-zsh-hook precmd () {
#  printf '\033[6 q'
#}

sshfslocal (){
        host=$1
        dir=$2
if [ -z "$dir" ]; then
        mkdir -p $HOME/remoteDir
        dir="$HOME/remoteDir"

fi
sshfs -o  idmap=user ${host} $dir && cd $dir
}


public (){
        xclip -sel clip ~/.ssh/id_rsa.pub
}

git-ssh-agent (){
	# Terminate any existing ssh-agent instances
	pkill ssh-agent 2>/dev/null
    # Start the ssh-agent if it's not running
    eval "$(ssh-agent -s)"
    
    # Find all private keys using file command to check file type
    private_keys=()
    for f in $HOME/.ssh/*; do
        if [[ -f "$f" && "$f" != *.pub ]] && file "$f" | grep -qi "private key"; then
            private_keys+=("$f")
        fi
    done
    
    # Use fzf for interactive selection if keys are found
    if [ ${#private_keys[@]} -gt 0 ]; then
        selected_keys=$(printf "%s\n" "${private_keys[@]}" | fzf --multi --header="Select SSH keys (TAB to select multiple, ENTER to confirm)")
        
        if [ -n "$selected_keys" ]; then
            echo "$selected_keys" | while read -r key; do
                ssh-add "$key" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "Added key: $key"
                fi
            done
        else
            echo "No keys selected."
        fi
    else
        echo "No private keys found in ~/.ssh/"
    fi
}


clean-copy (){
        rm -rf /run/user/1000/clipmenu*
        pgrep -f clipmenu | xargs  kill > /dev/null
        bspc wm -r
        echo "clipboard cleaned"
}

# Kubernetes functions 

function kubectl_pod_usage() {

    local namespace="$1"
    local label_selector="$2"

    if [[ -z "$namespace" ]]; then
        echo "Uso: kubectl_pod_usage <namespace> [label_selector]"
        echo "Ejemplo: kubectl_pod_usage default"
        echo "         kubectl_pod_usage default app=nginx"
        echo "         kubectl_pod_usage default app=nginx,version=v1"
        return 1
    fi

    # Build the metrics API URL with optional label selector
    local metrics_url="/apis/metrics.k8s.io/v1beta1/namespaces/$namespace/pods"
    if [[ -n "$label_selector" ]]; then
        metrics_url="$metrics_url?labelSelector=$label_selector"
    fi

    echo -e "POD_NAME\tCPU_USAGE\tMEMORY_USAGE"
    echo -e "--------\t---------\t------------"
    kubectl get --raw "$metrics_url" | jq -r '.items[] | 
        (.containers[0].usage.cpu // "0") as $cpu |
        (.containers[0].usage.memory // "0") as $mem |
        ($cpu | gsub("n$"; "") | tonumber / 1000000000) as $cpu_cores |
        ($mem | gsub("Ki$"; "") | tonumber / 1048576) as $mem_gb |
        "\(.metadata.name)\t\($cpu_cores | . * 1000 | round / 1000) cpu\t\($mem_gb | . * 100 | round / 100) GB"' | column -t | head -15
}

function kubectl_pod_request() {
    local namespace="$1"
    local label_selector="$2"

    if [[ -z "$namespace" ]]; then
        echo "Uso: kubectl_pod_request <namespace> [label_selector]"
        echo "Ejemplo: kubectl_pod_request default"
        echo "         kubectl_pod_request default app=nginx"
        echo "         kubectl_pod_request default app=nginx,version=v1"
        return 1
    fi

    echo -e "POD_NAME\tCPU_REQUEST\tMEMORY_REQUEST"
    echo -e "--------\t-----------\t--------------"

    # Call kubectl directly to avoid zsh interpreting an entire command string as a single command
    if [[ -n "$label_selector" ]]; then
        kubectl get pods -n "$namespace" -l "$label_selector" -o json | \
            jq -r '.items[] | select(.status.phase=="Running") | "\(.metadata.name)\t\(.spec.containers[0].resources.requests.cpu // "N/A")\t\(.spec.containers[0].resources.requests.memory // "N/A")"' | column -t | head -15
    else
        kubectl get pods -n "$namespace" -o json | \
            jq -r '.items[] | select(.status.phase=="Running") | "\(.metadata.name)\t\(.spec.containers[0].resources.requests.cpu // "N/A")\t\(.spec.containers[0].resources.requests.memory // "N/A")"' | column -t | head -15
    fi
}

function kubectl_node_resources() {
	kubectl get nodes -o custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory | \
	awk 'NR>1 {mem=$3; gsub(/[KMGi]+/, "", mem); printf "%-20s CPU: %s cores  Memory: %.2f GB\n", $1, $2, $3/1048576}'
}


sky(){
~/astroterm-linux-x86_64 --color --constellations --speed 100 --fps 20 --city Barcelona
}




################################################### plugins
plugins=(git
		     zsh-autosuggestions
		     zsh-syntax-highlighting
		)

source $ZSH/oh-my-zsh.sh
source <(kubectl completion zsh)
################################################### alias
alias lc="lsd -la"

alias icat="kitty +kitten icat"
#alias cat="bat --style=plain --theme TwoDark"
alias copy="xclip -sel clip"
alias ll="lsd -la"
alias vim="nvim"
alias master="sudo /usr/local/bin/reconnect-mm712.sh"
alias mountvault="sudo mount -t nfs santos.local:/Plex /NFS-Vault"
alias tn="tmux new -s"
alias tl="tmux ls"
alias ta="tmux a -t"
alias workspace="cd ~/workspace"
alias config="cd ~/configFiles"
alias k8s-syd='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-sydney"'
alias k8s-tek='export KUBECONFIG="${KUBECONFIG}:${HOME}/.kube/config-tekniker"'

#autoload -Uz add-zsh-hook
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# nvm (node version manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/neutry/.lmstudio/bin"
# End of LM Studio CLI section

# go lang
export PATH=$PATH:/usr/local/go/bin

# opencode
export PATH=/home/neutry/.opencode/bin:$PATH

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
