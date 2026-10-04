#!/usr/bin/env sh
# Perry-Agent installer: Perry (the assistant) + Agent Reach (internet access).
#
#   sh install.sh                 install both
#   sh install.sh --skip-perry    only add Agent Reach to an existing Perry
#   sh install.sh --uninstall     remove the Agent Reach skill from Perry
#
# Environment:
#   AGENT_REACH_REF   git tag/branch of Agent Reach to install (default: v1.5.0)
#   PERRY_HOME        Perry's home folder (default: ~/.perry)
set -eu

AGENT_REACH_REF="${AGENT_REACH_REF:-v1.5.0}"
PERRY_HOME="${PERRY_HOME:-$HOME/.perry}"
SKILL_DIR="$PERRY_HOME/skills/agent-reach"
PERRY_INSTALLER="https://raw.githubusercontent.com/TheM1N9/perry/main/install.sh"
AGENT_REACH_PKG="git+https://github.com/Panniantong/agent-reach.git@${AGENT_REACH_REF}"

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

SKIP_PERRY=0
for arg in "$@"; do
  case "$arg" in
    --skip-perry) SKIP_PERRY=1 ;;
    --uninstall)
      say "Removing $SKILL_DIR"
      rm -rf "$SKILL_DIR"
      echo "Done. To remove the tool itself: pipx uninstall agent-reach (or pip uninstall agent-reach)."
      exit 0 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) die "unknown option: $arg" ;;
  esac
done

# 1. Perry
if [ "$SKIP_PERRY" -eq 0 ]; then
  if have perry; then
    say "Perry is already installed, skipping"
  else
    say "Installing Perry (upstream installer: $PERRY_INSTALLER)"
    have curl || die "curl is required"
    curl -fsSL "$PERRY_INSTALLER" | sh
  fi
fi

# 2. Agent Reach (from the project repo; the PyPI package of the same name is not this project)
say "Installing Agent Reach $AGENT_REACH_REF"
have git || die "git is required"
have python3 || die "Python 3.10+ is required"
if have pipx; then
  pipx install --force "$AGENT_REACH_PKG"
else
  VENV="$HOME/.agent-reach-venv"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet --upgrade "$AGENT_REACH_PKG"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$VENV/bin/agent-reach" "$HOME/.local/bin/agent-reach"
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "note: add \$HOME/.local/bin to your PATH" ;; esac
fi
AR="$(command -v agent-reach || echo "$HOME/.local/bin/agent-reach")"

# 3. Environment check. No system packages are installed (that needs --system); it only
#    reports what is missing and registers Agent Reach's own skill under ~/.agents/skills.
say "Checking this machine (no system changes)"
"$AR" install --env=auto || true

# 4. Give Perry the skill, copied from the installed version so it always matches the tool.
say "Adding the skill to Perry ($SKILL_DIR)"
SRC="$("$(dirname "$AR")/python" -c 'import agent_reach,os;print(os.path.join(os.path.dirname(agent_reach.__file__),"skill"))' 2>/dev/null || true)"
if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  # pipx keeps its own venv: ask the tool's interpreter via the shebang
  PY="$(head -1 "$(readlink -f "$AR")" | sed 's/^#!//')"
  SRC="$($PY -c 'import agent_reach,os;print(os.path.join(os.path.dirname(agent_reach.__file__),"skill"))')"
fi
[ -f "$SRC/SKILL_en.md" ] || die "could not find Agent Reach's skill files"
rm -rf "$SKILL_DIR"
mkdir -p "$SKILL_DIR"
cp "$SRC/SKILL_en.md" "$SKILL_DIR/SKILL.md"
cp -R "$SRC/references" "$SKILL_DIR/references"

say "Done"
cat <<MSG

Next:
  agent-reach doctor            see which platforms work right now
  perry open                    open the dashboard and ask Perry:
                                "Research what people say about <topic> on Reddit and YouTube"

Platforms that need a login (Twitter/X, Reddit, Xiaohongshu...) stay off until you ask
Perry to "set up <platform>". Use a throwaway account, not your main one.
MSG
