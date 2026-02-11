#  Claude Code Configuration

> **Production-ready Claude Code configuration** with  enterprise workflows, and intelligent project detection.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🎯 What is This?

A complete, battle-tested Claude Code setup that gives your team:

- ✅ **27 Specialized Agents** - Expert AI workers for security, architecture, documentation, testing
- ✅ **19 Workflow Commands** - Slash commands for EPCC, TDD, security scans, code reviews
- ✅ **Automated Quality Gates** - Pre-commit hooks for linting, security scanning, formatting
- ✅ **One-Command Setup** - Intelligent project detection (Terraform, Python, Node.js, etc.)

---

## 🧠 Mental Model: How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      YOUR PROJECT                                │
│  .claude/ (symlinked to global config)                          │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│          Component Hierarchy & Information Flow                  │
└─────────────────────────────────────────────────────────────────┘

User Command: /security-scan src/auth.py
      │
      ▼
┌──────────────────┐
│    COMMAND       │  Workflow orchestrator
│  security-scan   │  • Parses arguments
│                  │  • Deploys agents
└────────┬─────────┘  • Coordinates work
         │
         ▼
┌──────────────────┐
│     AGENTS       │  Specialized AI workers
│ @security-review │  • Has expertise & instructions
│ @qa-engineer     │  • Performs specific tasks
│                  │  • Uses tools (Read, Grep, Bash)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│     SKILLS       │  Knowledge libraries (ALWAYS loaded)
│ security-*       │  • Domain expertise
│                  │  • Best practices
│                  │  • Code patterns
│                  │  • Anti-patterns
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│     HOOKS        │  Automated gates (OPTIONAL)
│  security_check  │  • Pre/Post tool execution
│  python_lint     │  • Quality enforcement
│                  │  • Auto-formatting
└──────────────────┘
```

### Component Relationships

| Component | Role                  | References                                      | Auto-Updates |
|-----------|-----------------------|-------------------------------------------------|--------------|
| **Skill** | Knowledge base        | Always loaded, always available                 | ✅ Yes       |
| **Agent** | Worker with expertise | Uses skills implicitly + tools explicitly       | ✅ Yes       |
| **Command** | Workflow orchestrator | Calls agents, references skills in docs       | ✅ Yes       |
| **Plan** | Step-by-step guide    | References skills & agents in workflow steps    | ✅ Yes       |
| **Hook** | Automation            | Runs scripts based on events                    | ✅ Yes       |

**Key Insight**: Skills, agents, commands, plans are **symlinked** → Update global once, all projects benefit!

---

## 📋 Prerequisites

Before setting up this configuration, ensure you have:

### 1. Claude Code License & Access
- **Register your intent**: Follow the [Adobe Wiki guide](https://wiki.corp.adobe.com/pages/viewpage.action?pageId=3500724262) to:
  - Obtain Claude Code license
  - Learn about Claude Code features
  - Understand Adobe's AI coding assistant policies

### 2. Claude Code Installation
Choose one of the following installation methods:

```bash
# Option A: Homebrew (recommended for macOS)
brew install claude

# Option B: npm (cross-platform)
npm install -g @anthropic-ai/claude-code
```

### 3. Shell Configuration (Zsh users)
If you're using Zsh (macOS default), install Oh My Zsh for better shell management:

```bash
# Install Oh My Zsh (if not already installed)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 4. Verify Installation
```bash
# Check Claude Code is available
claude --version

# Check shell environment
echo $SHELL  # Should show /bin/zsh or /bin/bash
```

---

## 🚀 Quick Start

### 1. Set Global Config Path

```bash
# Add to ~/.zshrc or ~/.bashrc
export CLAUDE_CONFIG_DIR="$HOME/decision-sciences-claude-config/.claude"
```

### 2. Install Functions

```bash
# For Zsh (Mac default)
cat decision-sciences-claude-config/setup/functions.zsh >> ~/.oh-my-zsh/custom/functions.zsh
source ~/.zshrc

# For Bash
cat decision-sciences-claude-config/setup/functions.bash >> ~/.bashrc
source ~/.bashrc
```

### 3. Setup Your Project

```bash
cd ~/your-project
setup-claude-config

# Output:
# 🔗 Symlinking: agents, commands, hooks, skills, plugins, plans
# 📦 Copying: ruff.toml, settings.json
# 🔍 Detected: terraform (+ docker)
# ✅ Setup complete!
```

### 4. Start Using

```bash
# Security scan
/security-scan src/ --deep

# Generate tests
/generate-tests src/api/auth.py --unit

# Code review
/code-review src/handlers/

# Full EPCC workflow
/epcc "add user authentication with MFA"
```

---

## 📊 What's Included


### Agents (27 specialists)
- **Architecture**: @architect, @system-designer, @architecture-documenter
- **Security**: @security-reviewer (Opus model for accuracy)
- **Testing**: @test-generator, @qa-engineer
- **Documentation**: @docs-tutorial, @docs-howto, @docs-reference, @docs-explanation
- **Performance**: @performance-profiler, @optimization-engineer
- **Deployment**: @deployment-agent
- **Agile**: @scrum-master, @product-owner, @business-analyst

### Commands (19 workflows)
- `/security-scan` - OWASP Top 10 security audit
- `/code-review` - Comprehensive code review
- `/generate-tests` - TDD test generation
- `/architecture-design` - System design
- `/epcc` - Explore-Plan-Code-Commit workflow
- `/tdd/tdd-feature` - TDD feature development
- `/docs/docs-create` - Smart documentation routing

---

## 🎓 Real-World Example: Building a Microservice

### Scenario: Create a secure Python FastAPI microservice for Adobe

```bash
# 1. Initialize project
cd ~/my-microservice
setup-claude-config
# Detected: python (+ docker)

# 2. Design architecture
/architecture-design "FastAPI microservice with PostgreSQL, Redis cache, deployed on Ethos"
# Agents: @architect designs system
# Output: Architecture diagram, component breakdown

# 3. Implement with security
/epcc "implement user authentication with JWT"
# Explore: Analyzes requirements
# Plan: Creates implementation strategy
# Code:
#   - @security-reviewer validates design
# Commit: Generates semantic commit message

# 4. Generate tests
/generate-tests src/api/auth.py --unit --integration
# Agents: @test-generator creates comprehensive tests
# Output: 90%+ test coverage

# 5. Security audit
/security-scan --deep --focus:authentication
# Agents: @security-reviewer @qa-engineer
# Output: Detailed vulnerability report with fixes

# 6. Document
/docs/docs-create "authentication API" --complete
# Agents: @docs-tutorial @docs-howto @docs-reference @docs-explanation
# Output: Complete documentation (4 types)

# 7. Review before merge
/code-review src/
# Agents: @architect @security-reviewer @qa-engineer
# Output: Comprehensive review with actionable feedback


## 🛠️ Management Commands

```bash
# Setup current project
setup-claude-config

# Check status
claude-config-status

# Update all your projects at once
update-all-claude-configs

# Clean up backup directories
clean-claude-backups
```

---

## 🏗️ Architecture Benefits

### Symlinked Components (Auto-Update)
```
Your Project
├── .claude/
│   ├── agents/     → SYMLINK to global
│   ├── commands/   → SYMLINK to global
│   ├── hooks/      → SYMLINK to global
│   └── plans/      → SYMLINK to global
```

**Benefit**: Update `decision-sciences-claude-config/.claude/` once → All projects get updates instantly!

### Project-Specific Configs (Copied)
```
│   ├── ruff.toml      → COPIED (customized per-project for Python version)
│   └── settings.json  → COPIED (customized per-project settings)
```

**Benefit**: Each project can customize these files independently (Python 3.11 vs 3.13, different linting rules, project-specific hook configurations)

---

## 📖 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - 5-minute setup
- **[EXAMPLES.md](./EXAMPLES.md)** - Adobe-specific workflows

---

## 🤝 Contributing


1. **Add Skills**: Create new skills in `.claude/skills/` directory with your team-specific patterns
2. **Add Commands**: Create new commands in `.claude/commands/` directory for custom workflows
3. **Commit & Push**: All team members get updates via git pull + symlinks!

---

## 📝 License

MIT License

---

## 🙏 Attribution & Acknowledgments

This repository is inspired by and builds upon:

- **Original Inspiration**: [AWS Anthropic Advanced Claude Code Patterns](https://github.com/aws-samples/anthropic-on-aws/tree/main/advanced-claude-code-patterns)


---

## 🆘 Support

- **Issues**: Open an issue in this repo

---

