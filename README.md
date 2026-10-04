<h1 align="center">Perry-Agent</h1>

<p align="center">
  <b>A personal AI assistant on your own computer, with eyes on the whole internet.</b><br>
  <a href="https://github.com/TheM1N9/perry">Perry</a> + <a href="https://github.com/Panniantong/agent-reach">Agent Reach</a>, installed with one command.
</p>

---

## What this is

| Piece | What it does | Upstream |
|---|---|---|
| **Perry** | An assistant you message on Telegram, WhatsApp or the web. It runs on your machine, remembers you, keeps to-dos and schedules, and works on your files. Its "brain" is the coding agent you already pay for (Codex, Claude Code, ...), so there's no API bill. | [TheM1N9/perry](https://github.com/TheM1N9/perry) (MIT) |
| **Agent Reach** | Gives an agent read/search access to the web, YouTube, RSS, GitHub, Twitter/X, Reddit, Bilibili, Xiaohongshu, LinkedIn, V2EX, Xueqiu, podcasts and more. It picks, installs and health-checks the best tool per platform; the agent then calls those tools directly. | [Panniantong/agent-reach](https://github.com/Panniantong/agent-reach) (MIT) |
| **Perry-Agent** (this repo) | The glue: an installer that sets up both and registers Agent Reach as a Perry skill. | **perry** |

This repo contains no copy of either project. It installs them from upstream, so you always get their code and their updates.

## Why

Perry can already work on your computer and your accounts. Without Agent Reach it is blind to most of the web: no YouTube transcripts, no Reddit threads, no Twitter/X search, no readable web pages. With the skill installed you can say:

- "Research what people say about *\<product\>* on Reddit and YouTube, and summarise."
- "What does this video cover?" (paste a YouTube or Bilibili link)
- "Every Monday, check these RSS feeds and tell me what's new."
- "Is anyone hitting the same bug as me? Check GitHub issues and Reddit."

## Install

macOS or Linux, with `git`, `curl` and Python 3.10+:

```bash
git clone https://github.com/snowjug/Perry-Agent
cd Perry-Agent
sh install.sh
```

The script:

1. Installs Perry with its official installer (skipped if `perry` is already on your PATH).
2. Installs Agent Reach, pinned to a release tag, with `pipx` if you have it, otherwise into `~/.agent-reach-venv`.
3. Runs `agent-reach install --env=auto`, a check that lists what's missing. It does **not** install system packages.
4. Copies Agent Reach's skill (English version plus its reference docs) into `~/.perry/skills/agent-reach/`, where Perry loads skills from.

Options:

```bash
sh install.sh --skip-perry     # you already have Perry
sh install.sh --uninstall      # remove the skill from Perry
AGENT_REACH_REF=main sh install.sh   # track Agent Reach's latest instead of the pinned tag
PERRY_HOME=/path sh install.sh       # Perry lives somewhere other than ~/.perry
```

Windows (PowerShell, with [git](https://git-scm.com/download/win) and [Python 3.10+](https://www.python.org/downloads/)):

```powershell
git clone https://github.com/snowjug/Perry-Agent $HOME\Desktop\Perry-Agent
cd $HOME\Desktop\Perry-Agent
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Same options as above: `-SkipPerry`, `-Uninstall`, and the `AGENT_REACH_REF` / `PERRY_HOME` environment variables. On Windows, Agent Reach goes into `%USERPROFILE%\.agent-reach-venv`.

## Use it

```bash
agent-reach doctor     # which platforms work right now, and which backend serves each
perry open             # open the dashboard, then just ask
```

**Works with no setup:** any web page, YouTube transcripts and search, RSS, GitHub (public), V2EX, Bilibili search.
**Needs a login you provide:** Twitter/X, Reddit, Facebook, Instagram, Xiaohongshu, LinkedIn, Boss直聘, Xueqiu. Tell Perry "set up Reddit" and it walks you through it.

## Safety notes

- Platforms that need cookies or a browser session can ban accounts that script them. Use a **throwaway account**, not your main one.
- Agent Reach keeps credentials in `~/.agent-reach/` on your machine only.
- Perry asks before anything outside its sandbox; Agent Reach's own installer needs `--system` before it touches the system. Review before you approve.
- The installer runs two upstream scripts/packages. Read them first if you want: [Perry's installer](https://github.com/TheM1N9/perry/blob/main/install.sh) and [Agent Reach](https://github.com/Panniantong/agent-reach).
- The PyPI package named `agent-reach` is **not** this project; install from GitHub as the script does.

## Updating

```bash
perry update
AGENT_REACH_REF=<new tag> sh install.sh --skip-perry
```

## Credits and licence

Perry © The Perry contributors, MIT. Agent Reach © Agent Eyes, MIT. They are separate projects and are not affiliated with this repo.
This repo's scripts and docs are MIT licensed (see [LICENSE](LICENSE)).
