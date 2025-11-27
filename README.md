# Superpowers MCP Server for Augment

An MCP (Model Context Protocol) server that brings the powerful [Superpowers](https://github.com/obra/superpowers) skills library to Augment CLI. Access proven workflows, expert techniques, and best practices directly in your AI coding assistant.

## What is This?

This MCP server exposes the Superpowers skills library as tools that Augment can use. Skills are expert-crafted workflows and processes that guide AI assistants to produce better results.

**Available Tools:**
- `find_skills` - List all available skills from both the superpowers library and your personal skills
- `use_skill` - Load a specific skill to guide your work

## Prerequisites

- **Node.js** v18 or higher ([Download](https://nodejs.org/))
- **Git** ([Download](https://git-scm.com/))
- **Augment CLI** with MCP support

## Quick Start

### 1. Clone and Install

```bash
git clone https://github.com/jmcdice/superpower-mcp.git
cd superpower-mcp
./install.sh
```

The installer will:
- Clone the upstream Superpowers repository to `~/.augment/superpowers`
- Create a personal skills directory at `~/.augment/skills`
- Install MCP server dependencies
- Provide configuration instructions

### 2. Configure Augment

Add the MCP server to your Augment configuration file (`~/.augment/settings.json`):

```json
{
  "mcpServers": {
    "superpowers": {
      "command": "node",
      "args": [
        "/path/to/superpower-mcp/superpowers-mcp.js"
      ]
    }
  }
}
```

**Note:** Replace `/path/to/superpower-mcp/` with the actual path where you cloned this repository. The installer will show you the exact path to use.

### 3. Restart Augment

Restart Augment to load the new MCP server.

### 4. Test It

Ask Augment:
```
"What skills are available?"
```

You should see a list of skills from the Superpowers library.

## Usage

### Finding Skills

Ask Augment to list available skills:
```
"Show me available skills"
"What skills can you use?"
```

Or use the tool directly:
```
find_skills()
```

### Using Skills

Load a skill by name:
```
"Use the brainstorming skill"
"Load the test-driven-development skill"
```

Or use the tool directly:
```
use_skill("superpowers:brainstorming")
use_skill("superpowers:test-driven-development")
```

### Skill Naming Convention

- **Superpowers skills**: `superpowers:skill-name` (from the upstream repository)
- **Personal skills**: `my-skill-name` (from `~/.augment/skills/`)

Personal skills with the same name as superpowers skills will override them.

## Creating Personal Skills

1. Create a directory in `~/.augment/skills/` with your skill name:
   ```bash
   mkdir -p ~/.augment/skills/my-custom-skill
   ```

2. Add a `SKILL.md` file with YAML frontmatter:
   ```markdown
   ---
   name: my-custom-skill
   description: Use when you need to do something specific
   ---

   # My Custom Skill

   ## Purpose
   [Describe what this skill does]

   ## When to Use
   [Describe when to use this skill]

   ## Process
   1. [Step 1]
   2. [Step 2]
   3. [Step 3]
   ```

3. The skill will automatically be available through `find_skills` and `use_skill`

## Architecture

This is an overlay approach that works with the upstream Superpowers repository:

- **Upstream repository**: `~/.augment/superpowers` (read-only, updated via git pull)
- **MCP server**: This repository (custom Augment integration)
- **Personal skills**: `~/.augment/skills` (your custom skills)

The MCP server reads skills from both the upstream repository and your personal skills directory.

## Management

### Update Superpowers

To get the latest skills from the upstream repository:

```bash
./install.sh update
```

Then restart Augment.

### Uninstall

```bash
./install.sh remove
```

This will:
- Remove the Superpowers repository (`~/.augment/superpowers`)
- Optionally remove your personal skills (`~/.augment/skills`)
- Keep the MCP server files (you can delete them manually if desired)

Don't forget to remove the MCP server configuration from `~/.augment/settings.json` and restart Augment.

## Troubleshooting

### MCP Server Not Showing Up

1. Check that the path in `~/.augment/settings.json` is correct
2. Verify Node.js is installed: `node --version` (should be v18+)
3. Check that dependencies are installed: `ls node_modules` in the repo directory
4. Restart Augment completely

### Skills Not Loading

1. Verify the Superpowers repository exists: `ls ~/.augment/superpowers/skills`
2. Run `./install.sh update` to refresh the repository
3. Check skill file format (must have YAML frontmatter and be named `SKILL.md`)

### Permission Errors

Make sure the install script is executable:
```bash
chmod +x install.sh
```

## Links

- **Superpowers Repository**: https://github.com/obra/superpowers
- **Blog Post**: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)
- **Model Context Protocol**: https://modelcontextprotocol.io/
- **Augment**: https://www.augmentcode.com/

## Contributing

Issues and pull requests are welcome\! This is a community project to make Superpowers accessible to Augment users.

## License

MIT License - See LICENSE file for details

The upstream Superpowers repository has its own license. Please refer to https://github.com/obra/superpowers for details.

## Credits

- **Superpowers** by [Jesse Vincent](https://github.com/obra)
- **MCP Server** integration for Augment
