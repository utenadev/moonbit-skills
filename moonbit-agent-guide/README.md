# MoonBit Agent Skill

## Provenance

Vendored from [moonbitlang/moonbit-agent-guide](https://github.com/moonbitlang/moonbit-agent-guide)
at commit `7262fb8` (2026-09-18), same content as `skills/moonbit-agent-guide`
in [moonbitlang/skills](https://github.com/moonbitlang/skills). Licensed under
Apache-2.0 (see `LICENSE`). Local edits: this provenance note, and a
"Reference Files" section appended to `SKILL.md`.

The upstream repository documents an [Agent Skill](https://agentskills.io/home) that teaches AI coding agents the MoonBit programming language and its toolchain.

## Integrate the Skill into your agent

Different AI assistants require different configuration methods. Below are guides for popular coding assistants:

### Codex CLI

```shell
mkdir -p ~/.codex/skills/
git clone https://github.com/moonbitlang/moonbit-agent-guide ~/.codex/skills/moonbit
```

Documentation: https://developers.openai.com/codex/skills

### Claude Code

```shell
mkdir -p ~/.claude/skills/
git clone https://github.com/moonbitlang/moonbit-agent-guide ~/.claude/skills/moonbit
```

Documentation: https://code.claude.com/docs/en/skills

### GitHub Copilot for VS Code

```shell
# enable moonbit skill for current repository
mkdir -p ./.github/skills/
git clone https://github.com/moonbitlang/moonbit-agent-guide ./.github/skills/moonbit
```

Agent Skills are supported in VS Code. See [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills) for configuration and discovery details.

### Cursor & Cursor CLI

Agent Skills are supported in the Cursor editor and CLI, including stable releases since Cursor 2.4.

Documentation: https://cursor.com/docs/skills

### Gemini CLI

Gemini CLI supports Agent Skills. Use `gemini skills install` to install skills and `/skills` to manage them in a session.

Documentation: https://geminicli.com/docs/cli/using-agent-skills/
