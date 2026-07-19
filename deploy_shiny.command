#!/bin/bash
# =============================================================================
# One-click deploy for the Evo-M1 Shiny app.
#
#   • On a Mac: just DOUBLE-CLICK this file (it opens Terminal and runs).
#   • Or from any terminal:  bash deploy_shiny.command
#
# You do NOT need to cd anywhere — the script finds its own folder (the repo
# root) automatically. It:
#   1. rebuilds the derived data        (Rscript __ShinyApp/build_data.R)
#   2. commits + pushes to GitHub       (the live app reads data from GitHub)
#   3. deploys to shinyapps.io          (rsconnect::deployApp)
#
# ONE-TIME SETUP (only needed once, ever):
#   • Install R, then in R:  install.packages(c("readxl","rsconnect"))
#   • Get your token at shinyapps.io -> Account -> Tokens -> Show secret, then
#     run it once in R:  rsconnect::setAccountInfo(name="...", token="...", secret="...")
#     (rsconnect remembers it afterwards, so this script needs no secrets.)
# =============================================================================
set -euo pipefail

# --- go to the repo root = the folder this script lives in -------------------
cd "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo "Repo: $(pwd)"
echo

if ! command -v Rscript >/dev/null 2>&1; then
  echo "❌ Rscript not found. Install R first (https://cran.r-project.org), then re-run."
  exit 1
fi

echo "==> 1/3  Rebuilding derived data (build_data.R) …"
Rscript __ShinyApp/build_data.R
echo

echo "==> 2/3  Committing + pushing to GitHub …"
git add -A
if git diff --cached --quiet; then
  echo "   (no changes to commit — repo already up to date)"
else
  git commit -m "Refresh Shiny app data $(date +%Y-%m-%d)"
fi
git push
echo

echo "==> 3/3  Deploying to shinyapps.io …"
Rscript -e 'rsconnect::deployApp(appDir="__ShinyApp", appName="evo-m1-brain-traits", appTitle="Evo-M1 Comparative Brain-Trait Data", forceUpdate=TRUE)'
echo
echo "✅ Done — the public URL (…shinyapps.io/evo-m1-brain-traits/) is printed just above."
