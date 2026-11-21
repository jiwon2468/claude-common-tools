# AI tools and skills, pinned to the versions reviewed (2026-11-21). Each step has a time limit
# and a failure only skips that tool, so a session always starts.
export PATH="$HOME/.local/bin:$PATH"
export DO_NOT_TRACK=1 DISABLE_TELEMETRY=1
mkdir -p "$HOME/.claude/skills"
T=$(mktemp -d)
# Agent-Reach (reads YouTube, web, GitHub ...)
( git clone -q https://github.com/Panniantong/Agent-Reach.git "$T/ar" &&
  git -C "$T/ar" checkout -q c70ae6da5d39bc90e09ad2ae0575ccc89f31e284 &&
  timeout 600 uv tool install -q --constraint "$T/ar/constraints.txt" "$T/ar" &&
  timeout 600 agent-reach setup >/dev/null ) || echo "setup: agent-reach failed"
# agent-browser CLI + its own up-to-date Chrome
timeout 600 npm i -g -s agent-browser@0.43.0 || echo "setup: agent-browser cli failed"
timeout 600 agent-browser install >/dev/null || echo "setup: agent-browser chrome failed"
# GSD coding agent (no Playwright Chromium download; Node downloads go through the proxy).
# Its RTK helper download sometimes crashes Node's proxy support, and GSD runs without it, so it is
# skipped. One retry, then the launcher is made executable (a reinstall over a failed one left it 644).
for try in 1 2; do
  NODE_USE_ENV_PROXY=1 NODE_NO_WARNINGS=1 PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 GSD_SKIP_RTK_INSTALL=1 \
    timeout 900 npm i -g -s @opengsd/gsd-pi@1.23.0 &&
    { chmod +x "$(npm root -g)/@opengsd/gsd-pi/dist/bootstrap.js" 2>/dev/null; break; }
  [ "$try" = 2 ] && echo "setup: gsd failed"
done
# Firecrawl CLI (for the firecrawl skill), pinned. Installed off PATH and reached through a wrapper
# that turns off its self-update, telemetry and feedback calls (self-update would undo the pin).
FC="$HOME/.local/share/firecrawl-cli"
if timeout 600 npm i -g -s --prefix "$FC" firecrawl-cli@1.30.0; then
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/firecrawl" <<EOF
#!/bin/sh
# Pinned firecrawl-cli 1.30.0 (reviewed 2026-11-21): no self-update, no telemetry, no feedback calls.
export FIRECRAWL_NO_AUTO_UPDATE=1 FIRECRAWL_NO_UPDATE_CHECK=1 FIRECRAWL_NO_TELEMETRY=1
export FIRECRAWL_NO_ENDPOINT_FEEDBACK=1 FIRECRAWL_NO_SEARCH_FEEDBACK=1
exec "$FC/bin/firecrawl" "\$@"
EOF
  chmod +x "$HOME/.local/bin/firecrawl"
else
  echo "setup: firecrawl cli failed"
fi
# PDF tools for the pdf skill. The skill itself (anthropic-skills:pdf) is synced from the claude.ai
# account to every session; its Python libraries and qpdf are not in the image. cffi repairs the
# image's system cryptography package, which pypdf loads and which crashes without it.
timeout 600 python3 -m pip install -q --root-user-action=ignore pypdf==7.1.1 pdfplumber==0.11.11 \
  reportlab==5.1.0 pdf2image==1.17.0 pillow==13.0.0 cffi==2.1.1 || echo "setup: pdf libraries failed"
{ timeout 300 apt-get install -y -qq qpdf ||
  { timeout 300 apt-get update -qq && timeout 300 apt-get install -y -qq qpdf; }; } >/dev/null 2>&1 ||
  echo "setup: qpdf failed"
# Skills (skills CLI, user-level, Claude Code only), each pinned to a reviewed commit
add_skill() {
  ( cd "$T" && timeout 300 npx -y skills@1.9.0 add "$1" -g -a claude-code -s "$2" -y >/dev/null ) ||
    echo "setup: skill $2 failed"
}
add_skill vercel-labs/agent-browser@1fde6b90e8f17474b2f122d4b4ce43a7fa0a6aa0 agent-browser
add_skill vercel-labs/skills@57217cf86ba38148a57af9e90d14a4c049558330 find-skills
add_skill Leonxlnx/taste-skill@f6b76575f949707b4e3c37cd86cb44b0b98643e8 design-taste-frontend
add_skill anthropics/skills@e4bb5d960d87126ff3b3a8af1a104b7db67560ba mcp-builder
add_skill firecrawl/cli@a9ce64e4d114fd203d8402ca000339d66e902cde firecrawl
add_skill nextlevelbuilder/ui-ux-pro-max-skill@f76d1653d7467fc11fb9d9d79295a421c92ab958 ui-ux-pro-max
add_skill obra/superpowers@22f0b463e7a5e579904dd6211a520321035526f7 systematic-debugging
# brainstorming: its optional visual companion page loads the author's logo (version only) when a browser
# opens it; set SUPERPOWERS_DISABLE_TELEMETRY=1 where that page is used to skip it
add_skill obra/superpowers@22f0b463e7a5e579904dd6211a520321035526f7 brainstorming
rm -rf "$T"
exit 0
