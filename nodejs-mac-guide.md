# How to Fix Multiple Node.js Installations on Mac

> **Everything in this guide is 100% free.** No purchases, subscriptions, or paid tools required.

If you installed Node.js more than once (e.g., once from nodejs.org and once via Homebrew), your Mac may have two copies and your Terminal may not know which one to use. This guide walks you through finding all copies, keeping the best one, and removing the rest.

---

## Step 1 — List All Node.js Installations

Open **Terminal** (press `Cmd + Space`, type `terminal`, press Enter).

Run each command below one at a time and read what each one tells you:

```sh
which node
```
> Shows the path that your Terminal currently uses when you type `node`.
> Example output: `/usr/local/bin/node`
> If it shows nothing, your PATH is not set up yet — that's OK, Step 4 fixes this.

```sh
which npm
```
> Same idea for `npm` (Node's package manager).

```sh
ls -l /usr/local/bin/node
```
> Checks if Node.js is installed via the **official .pkg installer** from nodejs.org.
> If it exists you'll see a file listing. If not, you'll see "No such file or directory".

```sh
ls -l /opt/homebrew/bin/node
```
> Checks if Node.js is installed via **Homebrew** (common on Apple Silicon Macs).
> On older Intel Macs the Homebrew path is `/usr/local/bin/node` instead.

```sh
ls -l ~/.nvm
```
> Checks if you have **nvm** (Node Version Manager) installed.
> A long directory listing means nvm exists. "No such file or directory" means it doesn't.

```sh
echo $PATH
```
> Shows all the directories your Mac searches when you run a command.
> Look for `/usr/local/bin`, `/opt/homebrew/bin`, or a path containing `.nvm`.

---

## Step 2 — Choose Which Installation to Keep

Here are your three options. Pick the one that fits you best:

| Option | Best for | How to update |
|---|---|---|
| **Official Installer** (nodejs.org) | Simplest setup, just want it to work | Re-download and install a new version |
| **Homebrew** | Easy updates from Terminal | `brew upgrade node` |
| **nvm** | Need to switch between Node versions | `nvm install <version>` |

**Recommendation for beginners:** Use the **official installer** or **Homebrew**.
- Homebrew is great if you already use it for other tools.
- nvm is the most powerful but has a bit more setup.

---

## Step 3 — Remove the Extra Installations

Only run the commands for the installation(s) you want to **remove**. Skip any that don't apply.

### A. Remove the Official .pkg Installer version

> ⚠️ **Warning:** The commands below use `sudo rm -rf`. This permanently deletes files with administrator rights. Double-check each path before pressing Enter. Only run these if the official installer was one you installed and want to remove.

```sh
sudo rm -rf /usr/local/bin/node
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/bin/npx
sudo rm -rf /usr/local/include/node
sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf /usr/local/share/man/man1/node.1
sudo rm -rf /usr/local/lib/dtrace/node.d
```

Your Mac will ask for your login password. Type it and press Enter (nothing will appear as you type — that's normal).

### B. Remove the Homebrew version

This is safe and does not require `sudo`:

```sh
brew uninstall node
```

If Homebrew itself is not installed, this command will simply say "command not found" — that means you don't have a Homebrew Node to remove, so skip this step.

### C. Remove an nvm-managed version

First, see which versions nvm has installed:

```sh
nvm list
```

Example output:
```
->     v18.17.0
       v20.12.1
```

Remove the version you don't want (replace `18.17.0` with the actual version number):

```sh
nvm uninstall 18.17.0
```

Repeat for every version you want to remove, keeping only one.

---

## Step 4 — Fix PATH If "node" Is Not Found

After cleanup, test whether Node.js is available:

```sh
node --version
```

**If you see a version number** (e.g., `v20.12.1`) → your PATH is fine, skip to Step 5.

**If you see `command not found`** → follow the fix below for the installer you kept.

### Fix for Official Installer or Homebrew (Intel Mac)

```sh
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Fix for Homebrew (Apple Silicon Mac — chip is M1/M2/M3/M4)

```sh
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Fix for nvm

Open your shell config file:

```sh
nano ~/.zshrc
```

Scroll to the bottom (use the arrow keys) and add these two lines if they are not already there:

```sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Save and exit: press `Ctrl + X`, then `Y`, then `Enter`.

Apply the changes:

```sh
source ~/.zshrc
```

---

## Step 5 — Test and Confirm

Run these three commands and verify you get sensible output:

```sh
node --version
npm --version
which node
```

**Example of correct output:**

```
v20.12.1
10.5.0
/usr/local/bin/node
```

What each line means:
- `v20.12.1` — Node.js is installed and responds. Your version number may be different; that's fine.
- `10.5.0` — npm (the Node package manager) is installed and responds.
- `/usr/local/bin/node` — only **one** path is shown. If you used Homebrew on Apple Silicon it will say `/opt/homebrew/bin/node`. If you used nvm it will show a path under `~/.nvm/versions/…`. Any single path is correct.

If all three commands return output without errors, you're done! You now have exactly one working Node.js installation and your Mac is ready for development.

---

## Quick Reference

| Task | Command |
|---|---|
| See active Node path | `which node` |
| Check all install locations | `ls -l /usr/local/bin/node` and `ls -l /opt/homebrew/bin/node` |
| Remove Homebrew Node | `brew uninstall node` |
| List nvm versions | `nvm list` |
| Remove an nvm version | `nvm uninstall <version>` |
| Check Node version | `node --version` |
| Check npm version | `npm --version` |
| Reload shell config | `source ~/.zshrc` |
