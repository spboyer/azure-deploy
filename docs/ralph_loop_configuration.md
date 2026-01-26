# Ralph Loop Configuration Guide

This comprehensive guide explains how to set up, configure, and run the Ralph Loop for continuous improvement and testing of the Azure Deploy skill.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Setup Instructions](#setup-instructions)
4. [Running Ralph Loop](#running-ralph-loop)
5. [Understanding PRD Files](#understanding-prd-files)
6. [Test Modes](#test-modes)
7. [Continuous Improvement Process](#continuous-improvement-process)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Completion Signal](#completion-signal)
11. [Summary](#summary)

## Overview

The Ralph Loop is an automated testing framework that continuously improves the Azure Deploy skill through iterative testing. It works by:

1. Reading test scenarios from PRD (Product Requirements Document) JSON files
2. Executing tests against the skill implementation
3. Validating results and updating test status
4. Logging progress and committing changes
5. Repeating until all tests pass or iterations are exhausted

**Key Components:**
- **Ralph Scripts** (`ralph.sh`, `ralph-once.sh`): Wrapper scripts that configure and run Ralph
- **PRD Files**: JSON files containing test scenarios and validation criteria
- **Prompt Files**: Instructions that guide Ralph's testing behavior
- **Test Scenarios**: Sample applications in `test-scenarios/` directory
- **Progress Log**: `progress.txt` tracks test execution history

## Prerequisites

### 1. Clone Ralph Framework

Ralph must be cloned as a sibling directory to `azure-deploy`:

```bash
cd ..
git clone https://github.com/soderlind/ralph
cd azure-deploy
```

Ralph will be automatically detected in these locations:
- `../ralph/` (sibling directory - recommended)
- `../../ralph/` (parent sibling)
- `~/ralph/` (home directory)

### 2. Install GitHub Copilot CLI

Ralph requires GitHub Copilot CLI to execute tests. Install using one of these methods:

```bash
# Using Homebrew (macOS/Linux) - for new installation
brew install copilot

# Or upgrade if already installed
brew upgrade copilot

# Using npm (cross-platform)
npm i -g @github/copilot

# Or using GitHub CLI extension
gh extension install github/gh-copilot
```

Verify installation:
```bash
# If installed via Homebrew/npm
copilot --version

# If installed via gh extension
gh copilot --version
```

### 3. Azure CLI (for Deployment Tests Only)

Deployment tests require Azure CLI and an active subscription:

```bash
# Install Azure CLI (if not already installed)
# macOS
brew install azure-cli

# Windows
winget install Microsoft.AzureCLI

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Authenticate
az login
az account show  # Verify active subscription
```

**Note**: Detection and local preview tests do NOT require Azure authentication.

## Setup Instructions

### Step 1: Verify Directory Structure

Ensure your workspace is organized correctly:

```
workspace/
├── ralph/                    # Ralph framework (cloned separately)
│   ├── ralph.sh
│   └── ralph-once.sh
└── azure-deploy/            # This repository
    ├── ralph/               # Ralph configuration for azure-deploy
    │   ├── plans/           # PRD files
    │   ├── prompts/         # Test instructions
    │   ├── ralph.sh         # Wrapper script (looped)
    │   └── ralph-once.sh    # Wrapper script (single run)
    ├── test-scenarios/      # Sample applications for testing
    └── SKILL.md             # The skill being tested
```

### Step 2: Review PRD Files

Three PRD files are available for different testing needs:

| PRD File | Purpose | Tests Included |
|----------|---------|----------------|
| `prd.json` | Full test suite | Detection + Deployment (all scenarios) |
| `prd-azure-deploy-detection.json` | Detection only | 6 detection tests (no Azure required) |
| `prd-azure-deploy-deploy.json` | Deployment only | 4 deployment tests (requires Azure) |

### Step 3: Configure Environment (Optional)

Set environment variables to customize Ralph behavior:

```bash
# Use specific Copilot model (default: gpt-5.2)
export MODEL=gpt-4o

# Set Azure subscription (if you have multiple)
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

## Running Ralph Loop

### Quick Start Commands

#### Run Detection Tests (No Azure Required)

```bash
# Single iteration
./ralph/ralph-once.sh --detection

# Loop 10 times (or until all tests pass)
./ralph/ralph.sh --detection 10
```

#### Run Deployment Tests (Requires Azure)

```bash
# Single iteration
./ralph/ralph-once.sh --deploy

# Loop 5 times
./ralph/ralph.sh --deploy 5
```

#### Run Full Test Suite

```bash
# Single iteration (detection + deployment)
./ralph/ralph-once.sh

# Loop 10 times
./ralph/ralph.sh 10
```

### Understanding the Output

When you run Ralph, you'll see:

```
=======================================
Azure Deploy Skill - Ralph Testing
=======================================
Mode: detection
Iterations: 10
Prompt: ralph/prompts/azure-deploy-detection.txt
PRD: ralph/plans/prd-azure-deploy-detection.json
Profile: locked

[Ralph output follows...]
```

**Key Output Indicators:**
- **Test execution**: Ralph will show which test it's working on
- **Progress updates**: Appended to `progress.txt`
- **Git commits**: Automatic commits after each successful test
- **Completion signal**: `<promise>COMPLETE</promise>` when all tests pass

### Command Reference

#### ralph.sh (Looped Execution)

```bash
./ralph/ralph.sh [--detection|--deploy] <iterations>
```

**Options:**
- `--detection`: Run detection tests only (no Azure resources created)
- `--deploy`: Run deployment tests only (creates/destroys Azure resources)
- `<iterations>`: Number of times to run (exits early if all tests pass)

**Examples:**
```bash
./ralph/ralph.sh 5                    # 5 full test iterations
./ralph/ralph.sh --detection 10       # 10 detection iterations
./ralph/ralph.sh --deploy 3           # 3 deployment iterations
```

#### ralph-once.sh (Single Execution)

```bash
./ralph/ralph-once.sh [--detection|--deploy]
```

**Options:**
- `--detection`: Run one detection test
- `--deploy`: Run one deployment test
- (no flag): Run one full test

**Examples:**
```bash
./ralph/ralph-once.sh                 # One full test
./ralph/ralph-once.sh --detection     # One detection test
./ralph/ralph-once.sh --deploy        # One deployment test
```

## Understanding PRD Files

PRD (Product Requirements Document) files are JSON arrays containing test scenarios. Each test has this structure:

```json
{
  "category": "detection",              // or "deployment", "local-preview"
  "description": "Human-readable test name",
  "scenario": "test-scenarios/react-app",
  "expected_service": "Static Web Apps",
  "expected_confidence": "MEDIUM",
  "steps": [
    "Step 1: Action to take",
    "Step 2: Expected result"
  ],
  "passes": false                       // Updated to true when test succeeds
}
```

### PRD Fields Explained

| Field | Required | Description |
|-------|----------|-------------|
| `category` | Yes | Test type: `detection`, `deployment`, or `local-preview` |
| `description` | Yes | Brief description of what the test validates |
| `scenario` | Yes | Path to test scenario directory |
| `expected_service` | Detection only | Expected Azure service recommendation |
| `expected_confidence` | Detection only | Expected confidence level (HIGH/MEDIUM/LOW) |
| `validation` | Deployment only | How to validate successful deployment (e.g., "curl returns 200") |
| `steps` | Yes | Array of steps Ralph should follow |
| `passes` | Yes | Boolean - false initially, updated to true when test succeeds |

### Test Execution Order

Ralph processes tests in the order they appear in the PRD file, executing the **first test with `passes: false`**. After each successful test:

1. Ralph updates `passes: false` → `passes: true` in the PRD
2. Appends progress details to `progress.txt`
3. Commits changes to git
4. Moves to the next failing test

## Test Modes

### Detection Tests (`--detection`)

**Purpose**: Validate that the skill correctly identifies application types and recommends appropriate Azure services.

**Security Profile**: `locked` (file operations only, no shell access)

**What Happens**:
1. Ralph navigates to the test scenario directory
2. Analyzes project files (package.json, requirements.txt, etc.)
3. Detects framework and application type
4. Compares detected service against expected value in PRD
5. Updates PRD if detection is correct

**Example Detection Test**:
```json
{
  "category": "detection",
  "description": "Detect React/Vite app as Static Web Apps",
  "scenario": "test-scenarios/react-app",
  "expected_service": "Static Web Apps",
  "expected_confidence": "MEDIUM",
  "passes": false
}
```

**Benefits**:
- Fast execution (no Azure resources)
- Safe to run frequently
- Tests core skill logic
- No costs incurred

### Deployment Tests (`--deploy`)

**Purpose**: Validate actual deployments to Azure with end-to-end testing.

**Security Profile**: `dev` (all tools enabled - needed for `az`, `swa`, `func` commands)

**What Happens**:
1. Ralph creates a unique Azure resource group
2. Provisions the required Azure service
3. Deploys the application
4. Validates deployment with curl
5. Cleans up all Azure resources

**Example Deployment Test**:
```json
{
  "category": "deployment",
  "description": "Deploy static HTML site to Static Web Apps",
  "scenario": "test-scenarios/static-html",
  "validation": "curl returns 'Hello from Azure Static Web Apps'",
  "steps": [
    "Create resource group",
    "Create Static Web App resource",
    "Deploy with swa deploy",
    "Validate with curl",
    "Delete resource group"
  ],
  "passes": false
}
```

**Benefits**:
- Tests complete deployment workflow
- Validates actual Azure integration
- Ensures skill guidance is accurate
- Catches real-world issues

**Considerations**:
- Requires Azure subscription and authentication
- Creates/deletes Azure resources (minor costs may apply)
- Slower than detection tests
- Should clean up resources properly

### Full Test Suite (No Flag)

Runs both detection and deployment tests in sequence. Uses the `dev` profile to support all operations.

## Continuous Improvement Process

Ralph Loop implements a continuous improvement cycle:

```
┌─────────────────────────────────────────────┐
│  1. Read PRD - Find Next Failing Test      │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│  2. Execute Test Against Skill              │
│     - Detection: Analyze project files      │
│     - Deployment: Deploy to Azure           │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│  3. Validate Results                        │
│     - Detection: Match expected service?    │
│     - Deployment: curl validation succeeds? │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│  4. Update PRD & Log Progress               │
│     - passes: false → true                  │
│     - Append to progress.txt                │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│  5. Commit Changes                          │
└──────────────┬──────────────────────────────┘
               ↓
┌─────────────────────────────────────────────┐
│  6. Repeat Until All Tests Pass             │
│     or Max Iterations Reached               │
└─────────────────────────────────────────────┘
```

### How Ralph Improves the Skill

When a test fails, Ralph:

1. **Analyzes the failure**: Reviews logs and error messages
2. **Identifies root cause**: Determines if the issue is in:
   - Skill logic (SKILL.md)
   - Test scenario setup
   - Documentation accuracy
3. **Makes corrections**: Updates the appropriate files
4. **Re-runs test**: Validates the fix
5. **Documents changes**: Updates progress.txt with learnings

### Progress Tracking

The `progress.txt` file maintains a running log of all test executions:

```
=== Iteration 1 ===
[2024-01-26] Detection test: React/Vite → Static Web Apps ✓
Updated prd-azure-deploy-detection.json: passes = true

=== Iteration 2 ===
[2024-01-26] Detection test: Python Flask → App Service ✓
Updated prd-azure-deploy-detection.json: passes = true
...
```

## Best Practices

### 1. Start with Detection Tests

Always run detection tests before deployment tests:

```bash
# First, validate detection logic (fast, no cost)
./ralph/ralph.sh --detection 10

# Then, validate deployments (slower, uses Azure resources)
./ralph/ralph.sh --deploy 5
```

**Why?** Detection tests catch logic errors quickly without incurring Azure costs.

### 2. Use Single Runs for Debugging

When debugging a specific test failure:

```bash
# Run once to see detailed output
./ralph/ralph-once.sh --detection

# Review progress.txt and PRD changes
cat progress.txt
git diff ralph/plans/
```

### 3. Monitor Resource Cleanup

For deployment tests, verify Azure resources are cleaned up:

```bash
# List resource groups (should be minimal after tests)
az group list --output table

# Clean up any leftover test resources
az group delete --name ralph-test-* --yes --no-wait
```

### 4. Version Control PRD Changes

PRD files are updated automatically. Track these changes:

```bash
# View PRD modifications
git log --oneline ralph/plans/

# See which tests are now passing
git diff HEAD~1 ralph/plans/prd.json
```

### 5. Set Reasonable Iteration Counts

Choose iteration counts based on test complexity:

- **Detection tests**: 10-20 iterations (fast)
- **Deployment tests**: 3-5 iterations (slower, creates resources)
- **Full suite**: 5-10 iterations (comprehensive)

### 6. Review Progress Regularly

Check progress.txt to understand test evolution:

```bash
# View recent progress
tail -n 50 progress.txt

# Search for specific test results
grep "Static Web Apps" progress.txt
```

### 7. Add New Tests Incrementally

When adding new test scenarios:

1. Create the test scenario directory in `test-scenarios/`
2. Add one test entry to the appropriate PRD file
3. Run Ralph once to validate: `./ralph/ralph-once.sh --detection`
4. Fix any issues before adding more tests

### 8. Use Appropriate Models

Different Copilot models have different capabilities:

```bash
# For complex deployment logic
MODEL=gpt-4o ./ralph/ralph.sh --deploy 3

# For faster detection tests
MODEL=gpt-3.5-turbo ./ralph/ralph.sh --detection 10
```

## Troubleshooting

### Ralph Not Found Error

**Error**: `Ralph not found. Please clone https://github.com/soderlind/ralph`

**Solution**:
```bash
cd ..
git clone https://github.com/soderlind/ralph
cd azure-deploy
./ralph/ralph-once.sh  # Try again
```

### Azure Authentication Errors

**Error**: `ERROR: Please run 'az login' to setup account.`

**Solution**:
```bash
az login
az account show  # Verify authentication
./ralph/ralph-once.sh --deploy
```

### Test Stuck or Not Progressing

**Symptoms**: Ralph keeps working on the same test

**Diagnosis**:
```bash
# Check which test is being attempted
tail progress.txt

# Review PRD to see current status
cat ralph/plans/prd-azure-deploy-detection.json | grep -A 5 '"passes": false'
```

**Solutions**:
1. **Increase iterations**: May need more attempts
2. **Fix test manually**: Update the PRD or skill logic directly
3. **Skip problematic test**: Temporarily set `passes: true` to move forward

### Static Web Apps Region Errors

**Error**: `Static Web Apps not available in this region`

**Solution**: Ralph automatically uses compatible regions (`centralus`, `eastus2`, `westus2`, `westeurope`), but if issues occur:

```bash
# Verify region availability
az staticwebapp list-locations --query "[]" --output table

# Scripts already handle this, but you can verify:
grep -r "centralus" ralph/prompts/
```

### Deployment Tests Fail with Timeout

**Symptoms**: Deployments start but validation fails

**Solution**:
```bash
# Check if resources were created
az group list --query "[?starts_with(name, 'ralph-test')]"

# Review the last deployment logs
az deployment group list --resource-group <resource-group-name>

# Manually clean up if needed
az group delete --name <resource-group-name> --yes
```

### PRD Not Updating

**Symptoms**: Test passes but PRD still shows `passes: false`

**Solution**:
1. Check git status: `git status ralph/plans/`
2. Verify Ralph has write permissions
3. Review progress.txt for errors
4. Manually update PRD and commit if needed

### Copilot CLI Issues

**Error**: `copilot: command not found` or `gh copilot: command not found`

**Solution**:
```bash
# Option 1: Install standalone Copilot CLI via Homebrew
brew install copilot

# Option 2: Install via npm
npm i -g @github/copilot

# Option 3: Install as GitHub CLI extension
# First install GitHub CLI if needed
brew install gh  # macOS
# or
winget install GitHub.cli  # Windows

# Then install Copilot extension
gh extension install github/gh-copilot

# Verify installation
copilot --version
# or if using gh extension:
gh copilot --version
```

### Tests Pass Locally but Fail in Ralph

**Diagnosis**: Different environment or configuration

**Solutions**:
1. Check environment variables: `env | grep AZURE`
2. Verify Node.js/Python versions match
3. Review Ralph's profile settings (locked vs dev)
4. Run tests manually to reproduce: `./test-detection.sh`

## Completion Signal

When all tests in the PRD have `passes: true`, Ralph outputs:

```
<promise>COMPLETE</promise>
```

This signals that:
- All configured tests have passed
- The skill is functioning as expected
- No further iterations are needed

You can then review the final state:

```bash
# View all passed tests
cat ralph/plans/prd.json | jq '.[] | select(.passes == true) | .description'

# Review complete progress log
cat progress.txt

# See all commits made during the loop
git log --oneline --since="1 day ago"
```

## Summary

The Ralph Loop provides automated, continuous testing for the Azure Deploy skill:

- **Detection tests**: Fast validation of app type detection and service recommendations
- **Deployment tests**: End-to-end validation with actual Azure deployments
- **Automated improvement**: Iteratively fixes issues and updates documentation
- **Progress tracking**: Detailed logs of all test executions and outcomes

**Quick Reference**:
```bash
# Detection only (fast, no Azure)
./ralph/ralph.sh --detection 10

# Deployment only (requires Azure)
./ralph/ralph.sh --deploy 5

# Full suite
./ralph/ralph.sh 10

# Single run for debugging
./ralph/ralph-once.sh --detection
```

For more information about Ralph, visit: https://github.com/soderlind/ralph