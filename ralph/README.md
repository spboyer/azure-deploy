# Ralph Testing for Azure Deploy Skill

This folder contains assets for running automated "Identify → Deploy → Test → Improve" loops using [Ralph](https://github.com/soderlind/ralph).

> **📖 For comprehensive documentation**, see the [Ralph Loop Configuration Guide](../docs/ralph_loop_configuration.md) which includes detailed setup instructions, test modes, best practices, and troubleshooting.

## Prerequisites

Before running Ralph tests:

1. **Clone Ralph** as a sibling directory:
   ```bash
   cd .. && git clone https://github.com/soderlind/ralph && cd azure-deploy
   ```

2. **Install GitHub Copilot CLI**:
   ```bash
   gh extension install github/gh-copilot
   ```

3. **Azure CLI** (for deployment tests only):
   ```bash
   az login
   ```

See the [full guide](../docs/ralph_loop_configuration.md#prerequisites) for detailed instructions.

## Quick Start

### Run Detection Tests Only (No Azure Resources)
```bash
./ralph/ralph-once.sh --detection     # Single run
./ralph/ralph.sh --detection 10       # Loop 10 times
```

### Run Deployment Tests (Creates/Destroys Azure Resources)
```bash
./ralph/ralph-once.sh --deploy        # Single run
./ralph/ralph.sh --deploy 5           # Loop 5 times
```

### Run Full Suite
```bash
./ralph/ralph-once.sh                 # Single run
./ralph/ralph.sh 10                   # Loop 10 times
```

## Folder Structure

```
ralph/
├── prompts/
│   ├── azure-deploy.txt              # Full test prompt
│   ├── azure-deploy-detection.txt    # Detection-only prompt
│   └── azure-deploy-deploy.txt       # Deployment-only prompt
├── plans/
│   ├── prd.json                      # Full test PRD
│   ├── prd-azure-deploy-detection.json
│   └── prd-azure-deploy-deploy.json
├── progress.txt                      # Running log of test iterations
├── ralph.sh                          # Looped runner wrapper
├── ralph-once.sh                     # Single-run wrapper
└── README.md                         # This file
```

## How It Works

1. **Ralph reads** the PRD and finds the first test with `passes: false`
2. **For detection tests**: Analyzes test scenario files, validates detection logic
3. **For deployment tests**: Creates Azure resources, deploys, validates via curl
4. **Updates PRD** to `passes: true` on success
5. **Logs progress** to `progress.txt`
6. **Commits changes** automatically
7. **Repeats** until all tests pass or iterations exhausted

## PRD Format

Each test item in the PRD JSON:

```json
{
  "category": "detection",           // or "deployment"
  "description": "Human-readable test name",
  "scenario": "test-scenarios/react-app",
  "expected_service": "Static Web Apps",
  "expected_confidence": "MEDIUM",
  "steps": ["Step 1", "Step 2", ...],
  "passes": false                    // Set to true when test passes
}
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL` | `gpt-5.2` | Copilot model to use |

## Permission Profiles

| Mode | Profile | What's Allowed |
|------|---------|----------------|
| `--detection` | `locked` | Write files only (no shell) |
| `--deploy` | `dev` | All tools (needed for az, swa, func) |
| (default) | `dev` | All tools |

## Adding New Tests

1. Create a test scenario in `test-scenarios/`
2. Add an entry to the appropriate PRD file
3. Run Ralph to verify

## Troubleshooting

### Ralph not found
```bash
# Clone Ralph as a sibling directory
cd .. && git clone https://github.com/soderlind/ralph && cd azure-deploy
```

### Azure auth issues
```bash
az login
az account show  # Verify logged in
```

### Tests stuck
- Check `progress.txt` for the last completed item
- Look for `<promise>COMPLETE</promise>` in logs
- Increase iterations if hitting the limit

## Completion Signal

When all tests pass, Ralph outputs:
```
<promise>COMPLETE</promise>
```

This signals the loop to exit early.
