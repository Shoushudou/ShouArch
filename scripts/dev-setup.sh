#!/bin/bash

# ShouArch Development Environment Setup

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Please run as regular user (will use sudo when needed)"
        exit 1
    fi
}

# Setup Docker
setup_docker() {
    print_status "Setting up Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Please install docker package first."
        return 1
    fi
    
    sudo systemctl enable docker || {
        print_warning "Failed to enable docker service"
        return 1
    }
    
    sudo systemctl start docker || {
        print_warning "Failed to start docker service"
        return 1
    }
    
    # Add user to docker group
    if ! groups $USER | grep -q '\bdocker\b'; then
        sudo usermod -aG docker $USER || {
            print_warning "Failed to add user to docker group"
            return 1
        }
        print_info "User added to docker group. Please logout and login again for changes to take effect."
    else
        print_info "User already in docker group"
    fi
    
    # Test docker installation
    if docker --version &> /dev/null; then
        print_status "Docker setup completed: $(docker --version)"
    else
        print_warning "Docker setup completed but version check failed"
    fi
}

# Setup Node.js environment
setup_node() {
    print_status "Setting up Node.js environment..."
    
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Please install nodejs package first."
        return 1
    fi
    
    print_info "Node.js version: $(node --version)"
    print_info "npm version: $(npm --version)"
    
    # Install global packages
    local packages=(
        "yarn"
        "pnpm"
        "typescript"
        "ts-node"
        "nodemon"
        "npm-check-updates"
        "create-react-app"
        "create-next-app"
        "vue-cli"
        "express-generator"
        "http-server"
        "pm2"
    )
    
    for pkg in "${packages[@]}"; do
        if ! npm list -g "$pkg" &> /dev/null; then
            print_info "Installing $pkg..."
            npm install -g "$pkg" || {
                print_warning "Failed to install $pkg"
            }
        else
            print_info "$pkg already installed"
        fi
    done
    
    # Setup npm global directory if needed
    if [[ ! -d ~/.npm-global ]]; then
        mkdir -p ~/.npm-global
        npm config set prefix ~/.npm-global
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
        print_info "Added npm global bin to PATH"
    fi
}

# Setup Python environment
setup_python() {
    print_status "Setting up Python environment..."
    
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        print_warning "Python not found. Please install python package first."
        return 1
    fi
    
    # Use python3 if available, otherwise python
    local python_cmd="python"
    if command -v python3 &> /dev/null; then
        python_cmd="python3"
    fi
    
    print_info "Python version: $($python_cmd --version)"
    
    # Create virtual environment directory
    local venv_dir="$HOME/venv"
    mkdir -p "$venv_dir"
    
    # Create main virtual environment
    local main_venv="$venv_dir/shouarch"
    if [[ ! -d "$main_venv" ]]; then
        print_info "Creating main virtual environment..."
        $python_cmd -m venv "$main_venv" || {
            print_warning "Failed to create virtual environment"
            return 1
        }
    else
        print_info "Virtual environment already exists"
    fi
    
    # Install common packages in virtual environment
    print_info "Installing common Python packages..."
    source "$main_venv/bin/activate"
    
    local python_packages=(
        "pip"
        "setuptools"
        "wheel"
        "virtualenv"
        "ipython"
        "jupyter"
        "numpy"
        "pandas"
        "matplotlib"
        "requests"
        "flask"
        "django"
        "black"  # code formatter
        "flake8" # linter
        "pytest"
    )
    
    for pkg in "${python_packages[@]}"; do
        if ! pip show "$pkg" &> /dev/null; then
            print_info "Installing $pkg..."
            pip install "$pkg" || {
                print_warning "Failed to install $pkg"
            }
        else
            print_info "$pkg already installed"
        fi
    done
    
    deactivate
    
    # Add virtual environment activation to bashrc
    if ! grep -q "source $main_venv/bin/activate" ~/.bashrc; then
        echo "# Python virtual environment" >> ~/.bashrc
        echo "alias pyenv='source $main_venv/bin/activate'" >> ~/.bashrc
        print_info "Added pyenv alias to bashrc"
    fi
    
    print_status "Python setup completed. Use 'pyenv' to activate virtual environment."
}

# Setup Rust environment
setup_rust() {
    print_status "Setting up Rust environment..."
    
    if ! command -v rustup &> /dev/null; then
        print_warning "Rust not found. Please install rustup first."
        return 1
    fi
    
    print_info "Rust version: $(rustc --version)"
    print_info "Cargo version: $(cargo --version)"
    
    # Install common cargo packages
    local cargo_packages=(
        "cargo-watch"
        "cargo-edit"
        "cargo-tree"
        "cargo-audit"
        "cargo-outdated"
        "cargo-bloat"
        "cargo-expand"
        "bat"          # cat clone with syntax highlighting
        "fd-find"      # find replacement
        "ripgrep"      # grep replacement
        "eza"          # ls replacement
        "starship"     # prompt
    )
    
    for pkg in "${cargo_packages[@]}"; do
        if ! cargo install --list | grep -q "$pkg"; then
            print_info "Installing $pkg..."
            cargo install "$pkg" || {
                print_warning "Failed to install $pkg"
            }
        else
            print_info "$pkg already installed"
        fi
    done
}

# Setup Go environment
setup_go() {
    print_status "Setting up Go environment..."
    
    if ! command -v go &> /dev/null; then
        print_warning "Go not found. Please install go package first."
        return 1
    fi
    
    print_info "Go version: $(go version)"
    
    # Setup Go workspace
    local go_path="$HOME/go"
    mkdir -p "$go_path"/{bin,src,pkg}
    
    # Set GOPATH if not already set
    if ! grep -q "export GOPATH" ~/.bashrc; then
        echo "# Go environment" >> ~/.bashrc
        echo "export GOPATH=$go_path" >> ~/.bashrc
        echo "export PATH=\$GOPATH/bin:\$PATH" >> ~/.bashrc
        print_info "Added GOPATH to bashrc"
    fi
    
    # Install common Go tools
    local go_tools=(
        "golang.org/x/tools/gopls@latest"                           # Language server
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest" # Linter
        "github.com/go-delve/delve/cmd/dlv@latest"                  # Debugger
        "github.com/cosmtrek/air@latest"                            # Live reload
    )
    
    for tool in "${go_tools[@]}"; do
        local tool_name=$(echo "$tool" | awk -F'/' '{print $NF}' | cut -d'@' -f1)
        if ! command -v "$tool_name" &> /dev/null; then
            print_info "Installing $tool_name..."
            go install "$tool" || {
                print_warning "Failed to install $tool_name"
            }
        else
            print_info "$tool_name already installed"
        fi
    done
}

# Setup Git configuration
setup_git() {
    print_status "Setting up Git..."
    
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Please install git package first."
        return 1
    fi
    
    # Configure Git if not already configured
    if [[ -z "$(git config --global user.name)" ]]; then
        read -p "Enter your Git name: " git_name
        git config --global user.name "$git_name"
    fi
    
    if [[ -z "$(git config --global user.email)" ]]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Set common Git configurations
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor "nvim"
    git config --global merge.tool "vimdiff"
    git config --global alias.co "checkout"
    git config --global alias.br "branch"
    git config --global alias.ci "commit"
    git config --global alias.st "status"
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.last "log -1 HEAD"
    
    print_info "Git configured:"
    print_info "  Name:  $(git config --global user.name)"
    print_info "  Email: $(git config --global user.email)"
}

# Setup development tools and utilities
setup_dev_tools() {
    print_status "Setting up development tools..."
    
    # Create development directory structure
    local dev_dirs=(
        "$HOME/Development"
        "$HOME/Development/projects"
        "$HOME/Development/learning"
        "$HOME/Development/temp"
    )
    
    for dir in "${dev_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # Install useful tools via package manager if available
    if command -v yay &> /dev/null; then
        local aur_tools=(
            "visual-studio-code-bin"
            "github-desktop-bin"
            "postman-bin"
            "insomnia-bin"
        )
        
        for tool in "${aur_tools[@]}"; do
            if ! yay -Qi "$tool" &> /dev/null; then
                print_info "Installing $tool from AUR..."
                yay -S --noconfirm "$tool" || {
                    print_warning "Failed to install $tool"
                }
            fi
        done
    fi
}

# Setup shell enhancements
setup_shell() {
    print_status "Setting up shell enhancements..."
    
    # Add useful aliases to bashrc
    if ! grep -q "# Development aliases" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# Development aliases
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias dc='docker-compose'
alias k='kubectl'
alias tf='terraform'
alias py='python'
alias ipy='ipython'
EOF
        print_info "Added development aliases to bashrc"
    fi
}

# Show setup summary
show_summary() {
    print_status "Development environment setup completed!"
    echo ""
    print_info "Available environments:"
    echo "  🐍 Python:    Use 'pyenv' to activate virtual environment"
    echo "  📦 Node.js:   Global packages installed (yarn, pnpm, typescript)"
    echo "  🦀 Rust:      Cargo tools installed"
    echo "  🐹 Go:        GOPATH configured, tools installed"
    echo "  🐳 Docker:    Service enabled, user added to docker group"
    echo "  🔧 Git:       Configured with useful aliases"
    echo ""
    print_warning "Please logout and login again for all changes to take effect."
    print_warning "Docker group membership requires re-login."
}

# Main setup function
main_setup() {
    print_status "Starting ShouArch development environment setup..."
    
    check_root
    
    setup_git
    setup_docker
    setup_node
    setup_python
    setup_rust
    setup_go
    setup_dev_tools
    setup_shell
    
    show_summary
}

# Individual setup functions
case "${1:-}" in
    "docker")
        setup_docker
        ;;
    "node")
        setup_node
        ;;
    "python")
        setup_python
        ;;
    "rust")
        setup_rust
        ;;
    "go")
        setup_go
        ;;
    "git")
        setup_git
        ;;
    "help"|"-h"|"--help")
        echo "ShouArch Development Environment Setup"
        echo ""
        echo "Usage: $0 [environment]"
        echo ""
        echo "Environments:"
        echo "  (no option)  Setup all environments"
        echo "  docker       Setup Docker only"
        echo "  node         Setup Node.js only"
        echo "  python       Setup Python only"
        echo "  rust         Setup Rust only"
        echo "  go           Setup Go only"
        echo "  git          Setup Git configuration"
        echo "  help         Show this help"
        ;;
    *)
        main_setup
        ;;
esac