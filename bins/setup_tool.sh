#!/bin/bash

# Tool and its install function
declare -A TOOLS=(
  ["terraform"]="install_terraform"
  ["node"]="install_node"
  ["python"]="install_python"
  ["aws"]="install_aws"
  ["kube"]="install_kube"
  ["go"]="install_go"
)

# Terraform installation function
install_terraform() {
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt update && sudo apt install terraform
}

# Node
install_node() {
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
}

# Python
install_python() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
    . $HOME/.local/bin/env
    uv python install 3.14
}

install_go(){
    curl -LO https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
    rm -f go1.24.2.linux-amd64.tar.gz
    export PATH="/usr/local/go/bin:$PATH"
    export GOPATH="$HOME/.local/share/go"
    export PATH="$GOPATH/bin:$PATH"
    go version
}

# AWS CLI
install_aws() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
    rm -rf awscliv2.zip aws
}

# Kubernetes
install_kube() {
    curl -Lo /usr/local/bin/kubectl \
	"https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x /usr/local/bin/kubectl
}

# Interactive selector (only useful if more tools are added later)
interactive_select() {
  local options=()
  for tool in "${!TOOLS[@]}"; do
    options+=("$tool" "" off)
  done

  local selected_tools
  if command -v whiptail >/dev/null 2>&1; then
    selected_tools=$(whiptail --title "Tool Installer" --checklist \
      "Select tools to install:" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3)
  elif command -v dialog >/dev/null 2>&1; then
    selected_tools=$(dialog --title "Tool Installer" --checklist \
      "Select tools to install:" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3)
  else
    echo "Error: whiptail or dialog is required." >&2
    exit 1
  fi

  echo $selected_tools
}

# Install selected tools
install_tools() {
  for tool in "$@"; do
    if [[ -n "${TOOLS[$tool]}" ]]; then
      "${TOOLS[$tool]}"
    else
      echo "❌ Unknown tool: $tool"
    fi
  done
}

# Entry point
if [[ $# -gt 0 ]]; then
  install_tools "$@"
else
  selected=$(interactive_select)
  selected=$(echo "$selected" | sed 's/"//g')
  install_tools $selected
fi

