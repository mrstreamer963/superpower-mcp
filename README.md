# Superpowers MCP Server

MCP (Model Context Protocol) server that connects the [Superpowers](https://github.com/obra/superpowers) skill library to any MCP-compatible assistant (Claude, Augment, etc.). Skills are expert workflows that improve AI assistant outcomes.

## What is this?

The server provides Superpowers skills as MCP tools.

**Available tools:**
- `find_skills` — list all available skills
- `use_skill` — load a specific skill for use

## Quick Start

### 1. Build the Docker Image

```bash
git clone https://github.com/mrstreamer963/superpower-mcp.git
cd superpower-mcp
make build
```

Or manually:

```bash
docker build -t superpower-mcp:latest .
```

### 2. Configure the MCP Client

Add the server to your MCP client configuration.

**For Claude Desktop (`claude_desktop_config.json`):**

```json
{
  "mcpServers": {
    "superpowers": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "superpower-mcp:latest"
      ]
    }
  }
}
```

**For Augment CLI (`~/.augment/settings.json`):**

```json
{
  "mcpServers": {
    "superpowers": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "superpower-mcp:latest"
      ]
    }
  }
}
```

> **Important:** Use the `-i --rm` flags (without `-t`) so the server runs in stdio mode, which is required for MCP.

### 3. Restart the Client

Restart your MCP client to load the new server.

### 4. Verification

Ask your assistant:

```
"What skills are available?"
```

You should see a list of skills from the Superpowers library.

## Usage

### Finding Skills

Ask the assistant to show available skills:

```
"Show available skills"
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

Or directly:

```
use_skill("brainstorming")
use_skill("test-driven-development")
```

All skills are from the Superpowers library and are prefixed with `superpowers:` in the output.

## Architecture

- **Docker image** — contains the Superpowers repository as a git submodule
- **MCP server** — runs inside the container, communicates via stdio
- **Client** — any MCP-compatible assistant (Claude, Augment, etc.)

## Management

### Updating Superpowers Skills

```bash
git pull                    # get the latest code
git submodule update --init --recursive  # update the built-in superpowers repository
make build                  # rebuild the image
```

After that, restart your MCP client.

### Removal

```bash
docker rmi superpower-mcp:latest
```

Don't forget to remove the server configuration from your MCP client settings.

## Troubleshooting

### Server Not Showing Up

1. Check that the image is built: `docker images superpower-mcp`
2. Check your MCP client configuration — the command should be `docker run -i --rm superpower-mcp:latest` (without `-t`)
3. Check that Docker is available: `docker --version`
4. Fully restart your MCP client

### Skills Not Loading

1. Check that the image contains skills: `docker run --rm superpower-mcp:latest ls /app/skills/superpowers/skills`
2. Rebuild the image after updating the submodule: `git submodule update --init --recursive && make build`

### Sanity Check

```bash
# Verify that the server responds via stdio
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | docker run -i --rm superpower-mcp:latest
```

This request should return JSON with the list of tools (`find_skills` and `use_skill`).

## Links

- **Superpowers Repository**: https://github.com/obra/superpowers
- **Blog Post**: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)
- **Model Context Protocol**: https://modelcontextprotocol.io/

## Contributing

Issues and pull requests are welcome!

## License

MIT License — see the LICENSE file for details.

The Superpowers repository has its own license. See https://github.com/obra/superpowers.

## Acknowledgments

- **Superpowers** by [Jesse Vincent](https://github.com/obra)
- **MCP Server** [integration](https://github.com/jmcdice/superpower-mcp/)