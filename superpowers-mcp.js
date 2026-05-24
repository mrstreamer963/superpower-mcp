#!/usr/bin/env node

/**
 * Superpowers MCP Server for Augment CLI
 *
 * Exposes skills from the superpowers repository as MCP tools.
 * Reads skills from:
 * - ~/.augment/superpowers/skills (upstream superpowers)
 * - ~/.augment/skills (personal skills)
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const currentDir = process.cwd();
const superpowersSkillsDir = path.join(currentDir, './skills/superpowers/skills');
const personalSkillsDir = path.join(currentDir, './skills');

/**
 * Extract YAML frontmatter from a skill file.
 */
function extractFrontmatter(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');

    let inFrontmatter = false;
    let name = '';
    let description = '';

    for (const line of lines) {
      if (line.trim() === '---') {
        if (inFrontmatter) break;
        inFrontmatter = true;
        continue;
      }

      if (inFrontmatter) {
        const match = line.match(/^(\w+):\s*(.*)$/);
        if (match) {
          const [, key, value] = match;
          if (key === 'name') name = value.trim();
          if (key === 'description') description = value.trim();
        }
      }
    }

    return { name, description };
  } catch (error) {
    return { name: '', description: '' };
  }
}

/**
 * Strip YAML frontmatter from skill content.
 */
function stripFrontmatter(content) {
  const lines = content.split('\n');
  let inFrontmatter = false;
  let frontmatterEnded = false;
  const contentLines = [];

  for (const line of lines) {
    if (line.trim() === '---') {
      if (inFrontmatter) {
        frontmatterEnded = true;
        continue;
      }
      inFrontmatter = true;
      continue;
    }

    if (frontmatterEnded || !inFrontmatter) {
      contentLines.push(line);
    }
  }

  return contentLines.join('\n').trim();
}

/**
 * Find all SKILL.md files in a directory recursively.
 */
function findSkillsInDir(dir, sourceType, maxDepth = 3) {
  const skills = [];

  if (!fs.existsSync(dir)) return skills;

  function recurse(currentDir, depth) {
    if (depth > maxDepth) return;

    const entries = fs.readdirSync(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);

      if (entry.isDirectory()) {
        const skillFile = path.join(fullPath, 'SKILL.md');
        if (fs.existsSync(skillFile)) {
          const { name, description } = extractFrontmatter(skillFile);
          skills.push({
            path: fullPath,
            skillFile: skillFile,
            name: name || entry.name,
            description: description || '',
            sourceType: sourceType,
            dirName: entry.name
          });
        }

        recurse(fullPath, depth + 1);
      }
    }
  }

  recurse(dir, 0);
  return skills;
}

/**
 * Resolve a skill name to its file path.
 */
function resolveSkillPath(skillName) {
  const forceSuperpowers = skillName.startsWith('superpowers:');
  const actualSkillName = forceSuperpowers ? skillName.replace(/^superpowers:/, '') : skillName;

  // Try personal skills first (unless explicitly superpowers:)
  if (!forceSuperpowers && personalSkillsDir) {
    const personalPath = path.join(personalSkillsDir, actualSkillName);
    const personalSkillFile = path.join(personalPath, 'SKILL.md');
    if (fs.existsSync(personalSkillFile)) {
      return {
        skillFile: personalSkillFile,
        sourceType: 'personal',
        skillPath: actualSkillName
      };
    }
  }

  // Try superpowers skills
  if (superpowersSkillsDir) {
    const superpowersPath = path.join(superpowersSkillsDir, actualSkillName);
    const superpowersSkillFile = path.join(superpowersPath, 'SKILL.md');
    if (fs.existsSync(superpowersSkillFile)) {
      return {
        skillFile: superpowersSkillFile,
        sourceType: 'superpowers',
        skillPath: actualSkillName
      };
    }
  }

  return null;
}

// Create the MCP server
const server = new Server(
  {
    name: 'superpowers',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List all available tools (skills)
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const personalSkills = findSkillsInDir(personalSkillsDir, 'personal', 3);
  const superpowersSkills = findSkillsInDir(superpowersSkillsDir, 'superpowers', 3);

  const allSkills = [...personalSkills, ...superpowersSkills];

  const tools = [
    {
      name: 'find_skills',
      description: 'List all available skills in the personal and superpowers skill libraries.',
      inputSchema: {
        type: 'object',
        properties: {},
        required: []
      }
    },
    {
      name: 'use_skill',
      description: 'Load and read a specific skill to guide your work. Skills contain proven workflows, mandatory processes, and expert techniques.',
      inputSchema: {
        type: 'object',
        properties: {
          skill_name: {
            type: 'string',
            description: 'Name of the skill to load (e.g., "superpowers:brainstorming", "my-custom-skill")'
          }
        },
        required: ['skill_name']
      }
    }
  ];

  return { tools };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'find_skills') {
    const personalSkills = findSkillsInDir(personalSkillsDir, 'personal', 3);
    const superpowersSkills = findSkillsInDir(superpowersSkillsDir, 'superpowers', 3);

    const allSkills = [...personalSkills, ...superpowersSkills];

    if (allSkills.length === 0) {
      return {
        content: [{
          type: 'text',
          text: 'No skills found. Install superpowers skills to ~/.augment/superpowers/skills/ or add personal skills to ~/.augment/skills/'
        }]
      };
    }

    let output = 'Available skills:\n\n';

    for (const skill of allSkills) {
      const namespace = skill.sourceType === 'personal' ? '' : 'superpowers:';
      const skillName = skill.name || path.basename(skill.path);

      output += `${namespace}${skillName}\n`;
      if (skill.description) {
        output += `  ${skill.description}\n`;
      }
      output += `  Directory: ${skill.path}\n\n`;
    }

    return {
      content: [{
        type: 'text',
        text: output
      }]
    };
  }

  if (name === 'use_skill') {
    const { skill_name } = args;

    const resolved = resolveSkillPath(skill_name);

    if (!resolved) {
      return {
        content: [{
          type: 'text',
          text: `Error: Skill "${skill_name}" not found.\n\nRun find_skills to see available skills.`
        }]
      };
    }

    const fullContent = fs.readFileSync(resolved.skillFile, 'utf8');
    const { name: skillDisplayName, description } = extractFrontmatter(resolved.skillFile);
    const content = stripFrontmatter(fullContent);
    const skillDirectory = path.dirname(resolved.skillFile);

    const skillHeader = `# ${skillDisplayName || skill_name}
# ${description || ''}
# Supporting tools and docs are in ${skillDirectory}
# ============================================`;

    return {
      content: [{
        type: 'text',
        text: `${skillHeader}\n\n${content}`
      }]
    };
  }

  throw new Error(`Unknown tool: ${name}`);
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Superpowers MCP server running on stdio');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});

