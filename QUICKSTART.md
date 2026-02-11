# Quick Start Guide

Get up and running with Adobe Claude Config in **5 minutes**.

---

## Prerequisites

- Claude Code installed ([claude.ai/code](https://claude.ai/code))
- Zsh or Bash shell
- Git

---

## Step 1: Clone This Repo (2 min)

```bash
cd ~/Documents/work
git clone <your-git-repo-url> decision-sciences-claude-config
```

---

## Step 2: Configure Environment (1 min)

```bash
echo 'export CLAUDE_CONFIG_DIR="$HOME/Documents/work/decision-sciences-claude-config/.claude"' >> ~/.zshrc
source ~/.zshrc
```

For Bash users, replace `~/.zshrc` with `~/.bashrc` in both commands.

---

## Step 3: Install Functions (1 min)

### For Zsh (macOS default):

```bash
cat ~/Documents/work/decision-sciences-claude-config/setup/functions.zsh >> ~/.oh-my-zsh/custom/functions.zsh
source ~/.zshrc
```

### For Bash:

```bash
cat ~/Documents/work/decision-sciences-claude-config/setup/functions.bash >> ~/.bashrc
source ~/.bashrc
```

---

## Step 4: Setup Your First Project (1 min)

```bash
cd ~/your-project
setup-claude-config
```

**Output:**
```
📁 Created .claude directory

🔗 Symlinking universal components (auto-update)...
   ✅ agents/ → symlinked
   ✅ commands/ → symlinked
   ✅ hooks/ → symlinked
   ✅ skills/ → symlinked
   ✅ plugins/ → symlinked
   ✅ plans/ → symlinked

📦 Copying project-specific config files...
   ✅ settings.json → copied (customizable)
   ✅ ruff.toml → copied (customizable)

🔍 Detecting project configuration...
   Project Type: python (+ docker)
   Python Version: 3.11

✅ Updated .gitignore

🎉 Claude config setup complete!
```

---

## Step 5: Start Using (immediately!)

```bash
# Security scan
/security-scan

# Generate tests
/generate-tests src/main.py

# Code review
/code-review

# Full EPCC workflow
/epcc "add user authentication"
```

---

## Verify Installation

```bash
# Check status
claude-config-status

# Should show:
# 🔗 Symlinked Components:
#    ✅ agents/ → ...
#    ✅ commands/ → ...
#    ✅ hooks/ → ...
#    ✅ skills/ → ...
```

---

## What's Next?

- **Read [EXAMPLES.md](./EXAMPLES.md)** - See real Adobe workflows
- **Read [README.md](./README.md)** - Understand how components work together
- **Customize** - Add your team's skills/commands to `.claude/`

---

## Troubleshooting

### "CLAUDE_CONFIG_DIR not set"

```bash
echo $CLAUDE_CONFIG_DIR
# Should output: /Users/you/Documents/work/decision-sciences-claude-config/.claude

# If empty, add to ~/.zshrc:
export CLAUDE_CONFIG_DIR="$HOME/Documents/work/decision-sciences-claude-config/.claude"
source ~/.zshrc
```

### "setup-claude-config: command not found"

```bash
# Re-install functions
cat ~/Documents/work/decision-sciences-claude-config/setup/functions.zsh >> ~/.oh-my-zsh/custom/functions.zsh
source ~/.zshrc
```

### Skills not showing up

```bash
# Check symlink
ls -la .claude/skills
# Should show: lrwxr-xr-x ... skills -> /path/to/decision-sciences-claude-config/.claude/skills
```

---

**That's it!** You're ready to build secure, high-quality code with Adobe standards built-in. 🚀
