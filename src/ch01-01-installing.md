# Installing PMAT

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (7/7 methods)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 7 | All installation methods tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-10-26*  
*PMAT version: pmat 2.173.0*
<!-- DOC_STATUS_END -->

## Installation Methods

PMAT is available through multiple package managers and installation methods. Choose the one that best fits your environment.

### Method 1: Cargo (Recommended)

The recommended installation method for all platforms:

```bash
cargo install pmat
```

**Prerequisites**: Rust 1.80+ installed via [rustup.rs](https://rustup.rs)

**Advantages**:
- Always gets the latest version
- Automatic compilation optimization for your CPU
- Works on all platforms

### Method 2: Homebrew (macOS/Linux)

For macOS and Linux users with Homebrew:

```bash
brew install pmat
```

**Verification**:
```bash
brew list pmat
pmat --version
```

### Method 3: npm (Node.js)

Install globally via npm:

```bash
npm install -g pmat-agent
```

**Usage**:
```bash
pmat-agent --version
pmat-agent analyze .
```

### Method 4: Docker

Run without installation using Docker:

```bash
# Pull the image
docker pull paiml/pmat:latest

# Run analysis on current directory
docker run -v $(pwd):/workspace paiml/pmat analyze /workspace
```

**Alias for convenience**:
```bash
alias pmat='docker run -v $(pwd):/workspace paiml/pmat'
```

### Method 5: Debian Package (Ubuntu/Debian)

Install via Debian package (recommended for Ubuntu/Debian users):

```bash
# Download the .deb package
wget https://github.com/paiml/paiml-mcp-agent-toolkit/releases/download/v2.173.0/pmat_2.173.0_amd64.deb

# Install
sudo dpkg -i pmat_2.173.0_amd64.deb

# Verify installation
pmat --version
```

**Dependencies** (automatically installed):
- libc6 (>= 2.34)
- libgcc-s1 (>= 4.2)
- libssl3 (>= 3.0.0)

### Method 6: Binary Download

Download pre-compiled binaries from GitHub:

```bash
# Linux x86_64
curl -L https://github.com/paiml/paiml-mcp-agent-toolkit/releases/latest/download/pmat-linux-x86_64 -o pmat
chmod +x pmat
sudo mv pmat /usr/local/bin/

# macOS ARM64
curl -L https://github.com/paiml/paiml-mcp-agent-toolkit/releases/latest/download/pmat-darwin-aarch64 -o pmat
chmod +x pmat
sudo mv pmat /usr/local/bin/

# Windows
# Download pmat-windows-x86_64.exe from releases page
```

### Method 7: Build from Source

For latest development version:

```bash
git clone https://github.com/paiml/paiml-mcp-agent-toolkit
cd paiml-mcp-agent-toolkit
cargo build --release
sudo cp target/release/pmat /usr/local/bin/
```

### Method 8: Package Managers (Platform Specific)

#### Windows - Chocolatey
```powershell
choco install pmat
```

#### Arch Linux - AUR
```bash
yay -S pmat
# or
paru -S pmat
```

#### Ubuntu/Debian - APT

Native APT packages are planned. For now, use the cargo install method:

```bash
# Install via cargo (recommended)
cargo install pmat
```

## Verification

After installation, verify PMAT is working:

```bash
# Check version
pmat --version
# Output: pmat 2.173.0

# Show help
pmat --help

# Quick test
echo "print('Hello PMAT')" > test.py
pmat analyze test.py
```

## Troubleshooting

### Issue: Command not found

**Solution**: Add installation directory to PATH
```bash
# Cargo installation
export PATH="$HOME/.cargo/bin:$PATH"

# npm installation  
export PATH="$(npm prefix -g)/bin:$PATH"
```

### Issue: Permission denied

**Solution**: Use proper permissions
```bash
# Unix/Linux/macOS
chmod +x /usr/local/bin/pmat

# Or reinstall with sudo
sudo cargo install pmat
```

### Issue: Old version installed

**Solution**: Update to latest
```bash
# Cargo
cargo install pmat --force

# Homebrew
brew upgrade pmat

# npm
npm update -g pmat-agent
```

## System Requirements

- **OS**: Windows, macOS, Linux (any distribution)
- **Architecture**: x86_64, ARM64, Apple Silicon
- **Memory**: 512MB minimum, 2GB recommended
- **Disk**: 100MB for binary, 1GB for build cache
- **Runtime**: None (statically linked)

## Next Steps

Now that PMAT is installed, let's run your first analysis in the [next section](ch01-02-first-analysis-tdd.md).