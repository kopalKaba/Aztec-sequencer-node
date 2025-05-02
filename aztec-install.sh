#!/bin/bash

# Function to print section headers
print_header() {
  echo -e "\n\033[1;36m==> $1\033[0m"
}

# Function to check command success
check_success() {
  if [ $? -ne 0 ]; then
    echo -e "\033[1;31m❌ $1 failed. Exiting.\033[0m"
    exit 1
  fi
}

# 1. Update and install dependencies
print_header "🔧 Updating system and installing dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
check_success "System update"

sudo apt install -y curl wget iptables build-essential git lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
check_success "Dependency installation"

# 2. Install Aztec tools
print_header "📦 Installing Aztec CLI tools..."
bash -i <(curl -s https://install.aztec.network)
check_success "Aztec install"

# 3. Add Aztec CLI to PATH
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 4. Update to alpha-testnet
print_header "🔄 Updating Aztec to alpha-testnet..."
aztec-up alpha-testnet
check_success "Aztec update"

# 5. Verify installation
print_header "✅ Verifying Aztec installation..."
aztec --version

# 6. Open necessary ports
print_header "🔓 Allowing firewall ports 40400 and 8080..."
sudo ufw allow 40400
sudo ufw allow 8080

# 7. Prompt for user input
print_header "📝 Enter required details for sequencer setup:"
read -p "🛰️  Sepolia RPC URL: " SEPOLIA_RPC
read -p "🔗 Consensus Host URL (Beacon Chain): " CONSENSUS_HOST
read -p "🔑 Your Private Key (start with 0x): " PRIVATE_KEY
read -p "🏦 Your Wallet Address (start with 0x): " WALLET_ADDRESS
IP_ADDR=$(curl -s ifconfig.me)
echo "🌐 Detected IP address: $IP_ADDR"

# 8. Start in screen session
print_header "🚀 Launching Aztec Sequencer inside a screen session..."

screen -dmS aztec bash -c "
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls $SEPOLIA_RPC \
  --l1-consensus-host-urls $CONSENSUS_HOST \
  --sequencer.validatorPrivateKey $PRIVATE_KEY \
  --sequencer.coinbase $WALLET_ADDRESS \
  --p2p.p2pIp $IP_ADDR"

check_success "Aztec sequencer launch"

# 9. Final message
print_header "🎉 Setup Complete!"
echo "🖥️  To check the sequencer: run \033[1;33mscreen -r aztec\033[0m"
echo "🔌 To detach from screen, press \033[1;33mCTRL+A then D\033[0m"
