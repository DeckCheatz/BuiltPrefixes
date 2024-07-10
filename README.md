# BuiltPrefixes

A Docker-based system for creating **generic** Wine prefixes using official Proton releases that work with **any** Windows application.

## Features

- **Universal Compatibility**: One prefix works with any Windows application or game
- **Official Sources**: Uses source tarballs from Proton-GE and Valve Proton releases  
- **Docker-based**: Consistent, reproducible builds across all platforms
- **Simple Architecture**: No platform-specific variations - just generic, reusable prefixes
- **CI/CD Pipeline**: Automated building with GitHub Actions
- **Easy Installation**: Pre-built archives with installation scripts

## Quick Start

### Using Pre-built Archives

Visit the [Releases page](https://github.com/DeckCheatz/BuiltPrefixes/releases) to download ready-to-use prefixes:

```bash
# Download and extract a prefix
wget https://github.com/DeckCheatz/BuiltPrefixes/releases/download/latest/proton-ge-GE-Proton10-10.tar.gz
tar -xzf proton-ge-GE-Proton10-10.tar.gz
cd proton-ge-GE-Proton10-10

# Install the prefix
./scripts/install-prefix.sh

# Run any Windows application
./scripts/run-app.sh /path/to/your/application.exe
./scripts/run-app.sh winecfg  # Configure Wine settings
```

### Building Your Own

#### Prerequisites

- Docker
- [Just](https://github.com/casey/just) (recommended task runner)

#### Build Commands

```bash
# Clone the repository
git clone https://github.com/DeckCheatz/BuiltPrefixes.git
cd BuiltPrefixes

# Build Docker image
just build-docker-image

# Build with latest Proton-GE
just build-ge-latest

# Build with latest Valve Proton
just build-valve-latest

# Build with specific versions
just build-ge GE-Proton10-10
just build-valve proton-9.0-4

# Install a built prefix
just install
```

#### Manual Docker Commands

```bash
# Build the Docker image
docker build -t wine-prefix-builder .

# Build a prefix with specific Proton version
docker run --rm --privileged \
  -v "$PWD/docker-scripts:/scripts:ro" \
  -v "$PWD/output:/output" \
  wine-prefix-builder \
  /scripts/build-prefix.sh "https://github.com/GloriousEggroll/proton-ge-custom/archive/GE-Proton10-10.tar.gz" /output
```

## Usage

### Installation and Setup

After building or downloading a prefix:

```bash
# Install to default location (~/.wine-prefixes/generic)
./scripts/install-prefix.sh

# Install to custom location  
./scripts/install-prefix.sh ~/.wine-prefixes/my-games

# Run any Windows executable
~/.wine-prefixes/generic/run-app.sh /path/to/game.exe
~/.wine-prefixes/generic/run-app.sh winecfg
```

### Running Applications

The generic prefix can run:

- **Games**: Steam, Epic, GOG, Origin, Ubisoft Connect, etc.
- **Applications**: Productivity software, utilities, etc.
- **Installers**: Setup files for any Windows software

### Advanced Package Management with Protontricks

BuiltPrefixes includes protontricks for advanced Wine package management:

```bash
# Setup protontricks (run once after installation)
~/.wine-prefixes/generic/scripts/setup-protontricks.sh

# Install Windows components
~/.wine-prefixes/generic/bin/protontricks --no-steam-runtime vcredist2019
~/.wine-prefixes/generic/bin/protontricks --no-steam-runtime dotnet48
~/.wine-prefixes/generic/bin/protontricks --no-steam-runtime dxvk

# Alternative winetricks interface
~/.wine-prefixes/generic/bin/winetricks-alt corefonts
```

See `PROTONTRICKS.md` in your installed prefix for a complete usage guide.

### Steam Integration

You can use these prefixes with Steam:

1. Install to a known location: `./scripts/install-prefix.sh ~/.local/share/steam/compatibilitytools.d/proton-custom`
2. In Steam, go to Settings → Compatibility → Enable Steam Play
3. Select the custom Proton installation

## Architecture

### Generic Prefix Design

Unlike platform-specific Wine configurations, BuiltPrefixes creates **universal** prefixes that:

- Use 64-bit Windows 10 compatibility
- Include comprehensive gaming components (SDL, CJK fonts, VKD3D, DXVK 2030, .NET Framework 4.8, vcrun2019, vcrun2022, corefonts)
- Work with DirectX 9/10/11/12, Vulkan, and OpenGL
- Support .NET Framework applications
- Handle legacy software with older Windows APIs

### Build Process

1. **Docker Environment**: Provides consistent, isolated build environment
2. **Proton Source**: Downloads and extracts official Proton releases
3. **Wine Initialization**: Creates clean 64-bit Wine prefix
4. **Dependencies**: Installs essential Windows redistributables
5. **Packaging**: Creates portable archives with installation scripts

## Development

### Available Commands

```bash
# Development
just info                    # Show project status
just list-releases           # List available Proton releases
just test-basic             # Test basic functionality

# Building
just build-docker-image     # Build Docker image
just build-ge GE-Proton10-10 # Build specific Proton-GE version
just build-valve proton-9.0-4 # Build specific Valve version

# Testing
just ci-test                # Simulate CI build process
just test-scripts           # Validate script permissions

# Maintenance
just clean                  # Clean build artifacts
just deep-clean             # Full cleanup including Docker
```

### File Structure

```
BuiltPrefixes/
├── docker-scripts/         # Docker container scripts
│   └── build-prefix.sh     # Main build script
├── scripts/                # Host utilities
│   └── fetch-proton-releases.sh # Release discovery
├── .github/workflows/      # CI/CD configuration
├── Dockerfile              # Docker image definition
├── Justfile                # Task automation
└── README.md
```

## CI/CD

The project uses GitHub Actions to:

- **Build Docker images** and push to GitHub Container Registry
- **Create prefixes** for latest Proton releases automatically
- **Generate releases** with downloadable archives
- **Run weekly** to catch new Proton versions

### Manual Workflow Trigger

Visit the [Actions page](https://github.com/DeckCheatz/BuiltPrefixes/actions) to manually trigger builds with specific parameters.

## Compatibility

These prefixes are tested and known to work with:

- **Modern Games**: Most DirectX 9/10/11/12 titles
- **Legacy Games**: Older Windows games via compatibility layers
- **Productivity Software**: Office suites, development tools
- **Media Applications**: Video/audio editing software
- **Emulators**: Windows-based console emulators

For game-specific compatibility, check [ProtonDB](https://www.protondb.com/).

## Contributing

1. Fork the repository
2. Make your changes
3. Test with `just ci-test`
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- [GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom) for Proton-GE
- [Valve](https://github.com/ValveSoftware/Proton) for official Proton
- [Wine](https://www.winehq.org/) project for Windows compatibility