# claude-common-tools

One installer for the command-line tools and Claude Code skills used in Claude Code cloud sessions.
Every tool and skill is pinned to the exact version that was read before it was added.

## Run

```bash
curl -fsSL https://raw.githubusercontent.com/jiwon2468/claude-common-tools/main/env_tools.sh -o /tmp/env_tools.sh
bash /tmp/env_tools.sh
```

Takes a few minutes. Running it again over an existing install is safe. A line starting with
`setup:` names one step that failed; the other steps still ran.

Run it only in a cloud or container session. It installs as root into global npm, pip, apt,
`~/.local` and `~/.claude/skills`.

## What it installs

- Programs: Agent-Reach, agent-browser (with its own Chrome), GSD, Firecrawl CLI, PDF tools
  (pypdf, pdfplumber, reportlab, pdf2image, qpdf)
- Skills (user level, Claude Code only): agent-browser, find-skills, design-taste-frontend,
  mcp-builder, firecrawl, ui-ux-pro-max, systematic-debugging, brainstorming, writing-plans,
  seo, python-testing, analytics, attribution, customer-research, competitor-profiling,
  copy-editing, schema, content-strategy, remotion, multimodal-audiocraft, hyperframes,
  hyperframes-cli, hyperframes-registry, media-use, remotion-to-hyperframes, reverse-any-video,
  slideshow, style-sampling, figma, pillar-content-architecture, the other 43 marketingskills skills
  (all except copywriting, cro and programmatic-seo), and the 17 social-media-skills skills
- Libraries for the account's pptx / docx skills: python-pptx, python-docx, lxml, defusedxml, pandas,
  pptxgenjs, react, react-dom, react-icons, sharp

Usage statistics and self-updates are turned off, so a pinned version stays pinned.
The HyperFrames skills are the exception on pinning: they call `npx hyperframes`, which this installer
does not install, so the CLI is whatever npx fetches on first use. Its usage statistics are turned off
through `~/.hyperframes/config.json`.

## Adding a tool or skill

1. Download it into a new empty folder and read the skill text and any install script.
2. Pin it to the commit or version you read.
3. Add one line to `env_tools.sh`, give the step a time limit, and let a failure skip only that step.
