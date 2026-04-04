# Claude + Apple Music Setup

Connects Claude Desktop to your Apple Music library so you can ask Claude
to explore and build historically-informed playlists in plain English.

## Requirements

- macOS on Apple Silicon (M1 or later) — Intel Macs are not supported
- Claude Desktop (download from claude.ai/download)
- An Apple Music subscription
- An internet connection during setup

## Installation

The `.dmg` file is just a delivery container — like a zip or a folder. It holds
the actual installer (`Claude Music Setup.command`) and this README. Opening the
`.dmg` mounts it as a read-only volume in Finder; nothing is installed at that
point. The installation happens when you run the `.command` file inside it.

### Step 1 — Open the disk image

Double-click **claude-music-setup.dmg**. A window opens showing two files:
`Claude Music Setup.command` and `README.md`.

### Step 2 — Run the installer

Double-click **Claude Music Setup.command**. This is the installer — Terminal
opens and the setup process starts automatically.

If macOS shows a warning that the file is from an unidentified developer,
right-click the file, choose **Open**, then click **Open** in the dialog that
appears. This is a one-time step because the installer is not signed with a
paid Apple Developer certificate — the script itself is safe to run.

### Step 3 — Follow the on-screen prompts

The installer will:

1. Confirm you are running macOS
2. Confirm Claude Desktop is installed — if it is not, it will tell you where
   to download it before continuing
3. Install Node.js 22 LTS if it is not already on your Mac (requires your
   Mac password at this step)
4. Add the music connector to Claude Desktop's configuration without
   disturbing any other connectors you may have set up
5. Open System Settings to the one screen where you need to grant a permission

The whole process takes about 2 minutes.

#### What the music connector is and how it works

Claude Desktop supports **MCP connectors** (Model Context Protocol) — small
servers that give Claude the ability to interact with apps and services on your
Mac. Without a connector, Claude can only have text conversations. With the
music connector installed, Claude gains a set of tools it can call to read your
Apple Music library, search for songs, and create or modify playlists.

The connector used by this installer is **music-mcp**, an open-source project
created by Pedro Cid ([@pedrocid](https://github.com/pedrocid)). The full source
code is publicly available at:

    https://github.com/pedrocid/music-mcp

You can review exactly what it does, report issues, or follow updates there. It
is released under the MIT license, which means it is free to use, inspect, and
modify. This installer fetches the latest published version from the npm registry
(`@pedrocid/music-mcp`) each time Claude starts — no separate download or update
step is needed.

When you ask Claude something like *"build me a playlist of 70s funk samples"*,
here is what happens behind the scenes:

1. Claude recognises that a music action is needed
2. It calls one of the music tools (e.g. search for tracks, create a playlist)
3. The connector receives that call and sends the corresponding AppleScript
   commands to the Music app on your Mac
4. Results (track names, confirmation, errors) are returned to Claude
5. Claude replies in chat with what it did

This all happens within the Claude Desktop app — no data leaves your Mac to a
third-party service. Claude's own cloud processing handles the language
understanding; the music connector handles the local Music app interaction.

The connector has no effect on Claude.ai in a web browser — it only works
inside the Claude Desktop app.

#### Library limitation — what Claude can and cannot add to a playlist

The connector can only work with songs that are **already in your personal
Apple Music library**. It searches your local library and adds matching tracks
to playlists from there. It cannot browse or pull from the Apple Music
streaming catalogue, so any song you have not previously added to your library
will not appear in search results and cannot be added automatically.

When you make a request, Claude will:

1. Build the playlist using whichever tracks from your request it can find in
   your library
2. Identify any tracks it could not find and tell you which ones are missing
3. Suggest those missing tracks by name so you can look them up in Apple Music
   and add them to your library manually

To add a missing track manually: find it in the Apple Music catalogue tab,
click the **+** button to add it to your library, then ask Claude to add it to
the playlist. Claude will be able to find it in your library from that point on.

#### Turning the connector on or off

The connector is registered in Claude Desktop's configuration file at:

    ~/Library/Application Support/Claude/claude_desktop_config.json

**To disable it temporarily** — the easiest way is inside Claude Desktop itself.
Click the **+** icon in the chat input bar, go to **Connectors**, and toggle the
music connector off. No restart required. To re-enable it, toggle it back on the
same way.

Alternatively, you can edit the configuration file directly: quit Claude Desktop,
open `~/Library/Application Support/Claude/claude_desktop_config.json` in a text
editor, remove the `"music"` block under `"mcpServers"`, save, and reopen Claude
Desktop.

**To re-enable it after a manual edit** — run this installer again. It will add
the entry back without affecting anything else in the file.

**To remove it permanently** — follow the disable steps above, then go to
**System Settings → Privacy & Security → Automation**, find Claude in the list,
and switch off the Music toggle.

### Step 4 — Grant the Automation permission

macOS requires you to personally approve Claude's access to control the Music
app. No script can do this on your behalf — it is a deliberate privacy
protection built into macOS.

When System Settings opens automatically at the end of the installer:

1. Go to **Privacy & Security → Automation**
2. Find **Claude** in the list
3. Switch on the toggle next to **Music**

### Step 5 — Restart Claude Desktop

Quit Claude Desktop and reopen it from your Applications folder. The music
tools will be active once it restarts.

---

## What to expect after setup

Open Claude Desktop and try one of the prompts below. Claude will search its
knowledge of music history, build the playlist, and add it directly to your
Apple Music library.

### Sampling and hip hop

- "Build a playlist of the 20 most sampled songs from the 1970s that were
  sampled in 80s and 90s hip hop. Call it 70s Hip Hop Samples."
- "Create a playlist of all the funk records that Dr. Dre sampled on The Chronic."
- "Make a playlist of James Brown tracks that were sampled in N.W.A songs."

### Folk and traditional music

- "Build a playlist tracing the folk ballads that Bob Dylan drew from in his
  early career, starting with their traditional origins."
- "Create a listening guide to the Appalachian and Celtic sources behind
  American bluegrass — one traditional version and one modern interpretation
  of each tune."

### Classical influence and lineage

- "Make a playlist of Beethoven's lesser-known works that directly influenced
  Brahms, paired with the Brahms pieces they shaped."
- "Build a playlist of the Hungarian and Romanian folk songs Bartók collected
  in the field, alongside his compositions that drew from them."

---

## Troubleshooting

**"Claude Desktop is not installed"**
Download Claude Desktop from claude.ai/download, install it, sign in, and
run the installer again.

**Node.js installation fails**
Download Node.js manually from nodejs.org (choose the LTS version), install
it, and then run the installer again.

**Claude is not listed in System Settings → Automation**
The entry only appears after Claude has attempted to use the music tools at
least once. Open Claude Desktop, type "Use the music info tool", then return
to System Settings → Privacy & Security → Automation and enable the Music
toggle under Claude.

**Music tools do not appear in Claude after setup**
Make sure you have fully quit and reopened Claude Desktop. If they still do
not appear, open the configuration file at:

    ~/Library/Application Support/Claude/claude_desktop_config.json

and confirm it contains a `"music"` entry under `"mcpServers"`.

---

## Manual installation

If you prefer to run the script yourself rather than using the disk image:

```bash
chmod +x install.sh
./install.sh
```

---

## Source and license

The music connector used by this installer is pedrocid/music-mcp, available
at github.com/pedrocid/music-mcp under the MIT license.

This installer is also released under the MIT license. You are free to
modify, share, and redistribute it.
