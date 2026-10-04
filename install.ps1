# Perry-Agent installer for Windows: Perry (the assistant) + Agent Reach (internet access).
#
#   .\install.ps1                 install both
#   .\install.ps1 -SkipPerry      only add Agent Reach to an existing Perry
#   .\install.ps1 -Uninstall      remove the Agent Reach skill from Perry
#
# Environment:
#   AGENT_REACH_REF   git tag/branch of Agent Reach to install (default: v1.5.0)
#   PERRY_HOME        Perry's home folder (default: ~\.perry)
param([switch]$SkipPerry, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'

$Ref       = if ($env:AGENT_REACH_REF) { $env:AGENT_REACH_REF } else { 'v1.5.0' }
$PerryHome = if ($env:PERRY_HOME) { $env:PERRY_HOME } else { Join-Path $HOME '.perry' }
$SkillDir  = Join-Path $PerryHome 'skills\agent-reach'
$Pkg       = "git+https://github.com/Panniantong/agent-reach.git@$Ref"
$Venv      = Join-Path $HOME '.agent-reach-venv'

function Say($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

if ($Uninstall) {
  Say "Removing $SkillDir"
  Remove-Item -Recurse -Force $SkillDir -ErrorAction SilentlyContinue
  Write-Host "Done. To remove the tool itself: delete $Venv"
  exit 0
}

# 1. Perry
if (-not $SkipPerry) {
  if (Have 'perry') { Say 'Perry is already installed, skipping' }
  else {
    Say 'Installing Perry (upstream installer)'
    Invoke-Expression (Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/TheM1N9/perry/main/install.ps1').Content
  }
}

# 2. Agent Reach (from the project repo; the PyPI package of the same name is not this project)
if (-not (Have 'git')) { throw 'git is required: https://git-scm.com/download/win' }
$py = if (Have 'py') { @('py','-3') } elseif (Have 'python') { @('python') } else { throw 'Python 3.10+ is required: https://www.python.org/downloads/' }
Say "Installing Agent Reach $Ref"
& $py[0] $py[1..($py.Length)] -m venv $Venv
$vpy = Join-Path $Venv 'Scripts\python.exe'
& $vpy -m pip install --quiet --upgrade $Pkg
if ($LASTEXITCODE -ne 0) { throw 'pip install of Agent Reach failed' }
$ar = Join-Path $Venv 'Scripts\agent-reach.exe'

# 3. Environment check. No system packages are installed (that needs --system).
Say 'Checking this machine (no system changes)'
& $ar install --env=auto

# 4. Give Perry the skill, copied from the installed version so it always matches the tool.
Say "Adding the skill to Perry ($SkillDir)"
$src = & $vpy -c "import agent_reach,os;print(os.path.join(os.path.dirname(agent_reach.__file__),'skill'))"
if (-not (Test-Path (Join-Path $src 'SKILL_en.md'))) { throw "could not find Agent Reach's skill files" }
Remove-Item -Recurse -Force $SkillDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $SkillDir | Out-Null
Copy-Item (Join-Path $src 'SKILL_en.md') (Join-Path $SkillDir 'SKILL.md')
Copy-Item -Recurse (Join-Path $src 'references') (Join-Path $SkillDir 'references')

Say 'Done'
Write-Host @"

Next:
  $ar doctor     see which platforms work right now
  perry open     open the dashboard and ask Perry:
                 "Research what people say about <topic> on Reddit and YouTube"

Platforms that need a login (Twitter/X, Reddit, Xiaohongshu...) stay off until you ask
Perry to "set up <platform>". Use a throwaway account, not your main one.
"@
