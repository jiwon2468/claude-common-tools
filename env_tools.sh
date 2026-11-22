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
# Libraries the claude.ai account's pptx / docx skills call "preinstalled": in this image they sit only
# in Python 3.13, while python3 is 3.11, and the deck libraries are missing. The skills themselves come
# from the account, so they are not installed here a second time.
timeout 600 python3 -m pip install -q --root-user-action=ignore python-pptx==1.0.2 python-docx==1.2.0 \
  lxml==6.1.3 defusedxml==0.7.1 pandas==3.0.5 || echo "setup: office python libraries failed"
timeout 600 npm i -g -s pptxgenjs@4.0.1 react@19.3.1 react-dom@19.3.1 react-icons@5.7.0 sharp@0.35.5 ||
  echo "setup: office node libraries failed"
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
add_skill obra/superpowers@22f0b463e7a5e579904dd6211a520321035526f7 writing-plans
# Two picked skills from ECC (affaan-m/ECC), read in full; the rest of ECC is not installed
add_skill affaan-m/ECC@4adeee6732a12d1540f49a4d50a38ce8c97f9a53 seo
add_skill affaan-m/ECC@4adeee6732a12d1540f49a4d50a38ce8c97f9a53 python-testing
# marketingskills: all skills except copywriting, cro and programmatic-seo, which projects often keep
# under those names. These seven were read first; the rest follow below in one call.
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 analytics
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 attribution
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 customer-research
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 competitor-profiling
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 copy-editing
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 schema
add_skill coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 content-strategy
# Several skills from one repo in one call (names split on spaces)
add_skills() {
  r=$1; shift
  ( cd "$T" && timeout 600 npx -y skills@1.9.0 add "$r" -g -a claude-code -s "$@" -y >/dev/null ) ||
    echo "setup: skills from $r failed"
}
# The other 43 marketingskills skills, read at the same commit. reverse-engineer-marketing ships a
# script that fetches a target site and web.archive.org only when run by hand.
add_skills coreyhaines31/marketingskills@5b2b400eec1e7e1cec76245a715d0b0d4fd2a9c1 \
  ab-testing ad-creative ads ai-seo aso churn-prevention co-marketing cold-email community- \
  marketing competitors conversion-tracking directory-submissions emails events free-tools \
  image influencer-marketing launch lead-magnets link-building marketing-council marketing- \
  ideas marketing-loops marketing-plan marketing-psychology offers onboarding paywalls \
  popups pricing product-marketing prospecting public-relations referrals reverse-engineer- \
  marketing revops sales-enablement seo-audit signup site-architecture sms social video
# social-media-skills (LinkedIn-first writing and image-prompt skills). reels-scripting sends a video to
# Apify and Gemini, and post-scorer pulls post history through Apify, only with the user's own keys.
add_skills charlie947/social-media-skills@10ca79c0ec0be0f7654d19cd4f0c86b6fa6ed23b \
  analytics-dashboard content-matrix gemini-carousel gemini-infographic graphic-designer \
  hook-generator newsletter-voice niche-research pinned-comment post-formatter post-scorer \
  post-writer profile-optimizer quote-post reels-scripting voice-builder youtube-thumbnail
# Video skills. remotion: Remotion best practices. multimodal-audiocraft: how to run MusicGen / AudioGen
# (the MusicGen weights are CC-BY-NC, so check the licence before publishing music made with them).
add_skill davila7/claude-code-templates@5a8853e7f0cbf5173451e329ae073250e6c442ca remotion
add_skill davila7/claude-code-templates@5a8853e7f0cbf5173451e329ae073250e6c442ca multimodal-audiocraft
# HyperFrames (HTML rendered to video): nine skills. They run `npx hyperframes`, which is not installed
# or pinned here, so npx fetches the current CLI on first use. That CLI and the media-use helper scripts
# send usage statistics, and each skill opens with a usage beacon; the settings file written below turns
# all of that off (both read it), unless the machine already has a saved preference.
[ -e "$HOME/.hyperframes/config.json" ] ||
  { mkdir -p "$HOME/.hyperframes" && echo '{"telemetryEnabled": false}' > "$HOME/.hyperframes/config.json"; } ||
  echo "setup: hyperframes usage-statistics opt-out failed"
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 hyperframes
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 hyperframes-cli
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 hyperframes-registry
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 media-use
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 remotion-to-hyperframes
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 reverse-any-video
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 slideshow
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 style-sampling
add_skill heygen-com/hyperframes@a8fe3a5b6844c9f1ae1a4473793eeb11dfcec627 figma
# Content hub design (pillar and cluster pages, internal links, URL structure); text only, no scripts
add_skill rampstackco/claude-skills@9d281db6e7a5c4a0084ba89c91633a07f5f7e42b pillar-content-architecture
rm -rf "$T"
exit 0
