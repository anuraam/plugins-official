# Setup Guide

The `web-app-tester` plugin has three prerequisites: Python 3.10+ with Playwright, and a platform CLI or token depending on whether your repository is on GitHub or Azure DevOps.

For named environments, authenticated testing (storage states), and read-only enforcement, add a `.web-app-tester.json` to the consumer repo — see [configuration.md](configuration.md). Without it, the plugin scrapes the test URL from comments as before.

---

## Python 3.10+

Python is required for the Webwright-based browser automation.

Verify:
```bash
python3 --version   # must be 3.10 or higher
```

Install from [python.org](https://python.org) if not present.

---

## Playwright Python Package

The plugin uses the Playwright Python library (not the Node.js `playwright-cli` binary) to drive a headless Chromium browser.

**Install:**

```bash
pip install playwright
playwright install chromium
```

Verify:
```bash
python3 -c "import playwright; print('ok')"
```

### Chromium Browser Caching

On the first test run the plugin downloads Chromium (~120 MB) if not already present. This takes ~20–40 seconds.

**Every subsequent run skips the install entirely** — the plugin probes for a working Chromium launch before executing the test plan.

### Chromium System Dependencies

Headless Chromium needs system shared libraries (`libnss3`, `libglib-2.0.so.0`, and others). The plugin installs these automatically via `playwright install --with-deps chromium` when the runner has root/`sudo`.

**Sandboxed or rootless runners cannot install these at runtime.** If you see the run report all steps as `BLOCKED` with a missing-shared-libraries message, bake the deps into the runner image instead:

```dockerfile
RUN pip install playwright \
    && playwright install --with-deps chromium \
    && rm -rf /var/lib/apt/lists/*
```

Or base the image on Microsoft's prebuilt Playwright image, which ships Chromium + every system dep already:

```dockerfile
FROM mcr.microsoft.com/playwright/python:v1.49.0-jammy
```

The plugin runs a one-shot launch probe before executing the test plan, so a misconfigured image fails fast with this exact guidance instead of timing out across every step.

---

## GitHub CLI

Required when your repository is hosted on GitHub (`github.com` in the remote URL).

The plugin uses `gh` to read PR/issue content and post the results comment.

### Installation

| Platform | Command |
|---|---|
| macOS | `brew install gh` |
| Windows | `winget install GitHub.cli` |
| Linux (Debian/Ubuntu) | `apt install gh` |

### Authentication

```bash
gh auth login
```

Or set the environment variable:

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

### Token Permissions

| Permission | Access | Why it's needed |
|---|---|---|
| **Metadata** | Read | Resolve repository owner and name |
| **Issues** | Read & Write | Fetch issue content and post result comments |
| **Pull requests** | Read & Write | Fetch PR content and post result comments |

---

## Azure DevOps

Required when your repository is hosted on Azure DevOps (`dev.azure.com` or `visualstudio.com` in the remote URL).

The plugin uses `curl` with a Personal Access Token (PAT) to read PR/work item content and post result comments.

### Prerequisites

- `curl` must be available (`curl --version`)
- `python3` must be available — used for browser automation and JSON serialisation in ADO API calls (`python3 --version`)

### Creating a Personal Access Token

1. In Azure DevOps, go to **User Settings → Personal access tokens**
2. Click **New Token**
3. Set the following scopes:

| Scope | Access | Why it's needed |
|---|---|---|
| **Work Items** | Read & Write | Fetch bug repro steps and acceptance criteria; post notification comments. Verify mode (`/verify-bug`) also needs Write to post the verdict comment, upload screenshot attachments, and (interactive only) apply a confirmed state transition |
| **Code** | Read | Access PR metadata, threads, and linked items |
| **Pull Requests** | Read & Write | Fetch PR content and post test execution report |

4. Copy the token value — it is shown only once.

### Setting the Token

```bash
export AZURE-DEVOPS-TOKEN=your_pat_here
```

Add this to your shell profile (`.bashrc`, `.zshrc`, etc.) to persist it across sessions.

### Remote URL Formats

The plugin auto-detects the Azure DevOps organisation, project, and repository from the git remote URL. Both URL formats are supported:

| Format | Example |
|---|---|
| Modern | `https://dev.azure.com/{org}/{project}/_git/{repo}` |
| Legacy | `https://{org}.visualstudio.com/{project}/_git/{repo}` |

Verify your remote:
```bash
git remote get-url origin
```

---

## Troubleshooting

**`python3: command not found`**
Install Python 3.10+ from [python.org](https://python.org) and ensure it is on your PATH.

**`ModuleNotFoundError: No module named 'playwright'`**
Run `pip install playwright && playwright install chromium`.

**`gh: command not found`**
Install the `gh` CLI using the instructions above.

**`gh auth status` fails**
Run `gh auth login` or export `GITHUB_TOKEN` with a valid personal access token.

**`UnicodeEncodeError: 'charmap' codec can't encode character ...` (Windows)**
Windows defaults Python's stdio and `open()` to a legacy codepage (cp1252), which crashes when a script prints page content containing non-ASCII glyphs (e.g. "❯"). The plugin's skill runs every Python invocation with `PYTHONUTF8=1` and opens its log file with `encoding="utf-8"` to prevent this. If you run scripts manually, apply the same prefix: `PYTHONUTF8=1 python script.py`.

**`_wat_run/` directory left in project directory**
The plugin deletes this directory at the end of every run, including failed runs. If it persists, the run was interrupted before cleanup. Delete it manually: `rm -rf _wat_run/`.

**All steps `BLOCKED` with "missing system shared libraries" / `libnss3` / `libglib-2.0.so.0`**
The runner image is missing Chromium's native deps and lacks root to install them at runtime. See the **Chromium System Dependencies** section above — bake `playwright install --with-deps chromium` into the image, or switch to `mcr.microsoft.com/playwright/python:v1.49.0-jammy`.

**`AZURE-DEVOPS-TOKEN is not set`**
Export the token: `export AZURE-DEVOPS-TOKEN=your_pat_here`. Create a PAT in Azure DevOps with Work Items (Read+Write), Code (Read), and Pull Requests (Read+Write) scopes.

**`curl` returns 401 for Azure DevOps**
The PAT may have expired or have insufficient scopes. Re-generate the token in Azure DevOps and re-export `AZURE-DEVOPS-TOKEN`.

**`wi` entry returns "no linked PR found"**
The work item must have at least one pull request linked via the Azure DevOps PR → Work Items relationship. Link the PR from the PR creation page or the work item's "Links" tab, then re-trigger.
