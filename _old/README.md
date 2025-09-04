# Homebrew Witco

Private Homebrew tap for Witco CLI tools.

## Installation

```bash
brew tap realgeeks/witco
brew install realgeeks/witco/witco-cli
```

Or in one command:
```bash
brew install realgeeks/witco/witco-cli
```

## Prerequisites

- macOS 12.0 or later
- Homebrew installed
- AWS SSO access to Witco organization

## Available Formulas

- `witco-cli` - Private CLI tool for Witco operations

## Troubleshooting

If you encounter authentication issues:

```bash
aws sso login --profile witco-cli
```

## Support

For issues or questions, please open an issue in this repository.