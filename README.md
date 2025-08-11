# kometa-configs

<img width="1201" height="431" alt="Image showing data flowing between different services with a text box saying 'you are here' pointed at GitHub" src="https://github.com/user-attachments/assets/c5ccee69-abbc-4d3e-bfb6-e545ea7cd1e5" />


This repository contains a collection of configuration files for use with **Kometa**, designed to manage metadata, playlists, collections, and more for a Plex instance.

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Metadata Automation](#metadata-automation)
- [Manual Metadata Management](#manual-metadata-management)
- [Collections & Playlists](#collections--playlists)
- [Workflows & Automation](#workflows--automation)
- [Testing](#testing)
- [Contributing](#contributing)
- [FAQ](#faq)
- [Links & Resources](#links--resources)

---

## Overview

This repository centralizes your Plex metadata, collections, and playlist configurations as code. It enables automated and manual updates, preserves customizations, and ensures easy recovery or migration for your media library using **Kometa** and supporting tools.

---

## Repository Structure

```
kometa-configs/
├── .github/workflows/       # GitHub Actions for automation (import, linting, sorting, manual add, etc.)
├── functions/               # Bash scripts for reused logic (manipulating metadata, sorting, formatting, etc.)
├── node-red/                # Node-RED flows for processing webhooks from Servarr apps
├── scripts/                 # Python scripts for one-time or advanced operations
├── tests/                   # Bats test suite for shell functions.
├── movie-collections.yml    # Collection definitions for movies
├── show-collections.yml     # Collection definitions for TV shows
├── movie-metadata.yml       # Centralized metadata for movies (auto-updated)
├── show-metadata.yml        # Centralized metadata for TV shows (auto-updated)
└── playlists.yml            # Playlist definitions and rules
```

---

## Getting Started

### Prerequisites

- A running Plex Media Server
- [Kometa](https://kometa.wiki/en/latest/)
- [Sonarr](https://sonarr.tv/) and/or [Radarr](https://radarr.video/)
- [Node-Red](https://nodered.org/) (to bridge webhooks & GitHub)
- A fork of this repository

### Quick Start

1. **Fork this repository.**
2. **[Set up Node-Red with the provided flow.](/node-red/metadata-update-flow.json)**
3. **Configure Servarr webhooks** to POST to your Node-Red instance.
4. **[Point Kometa to your repo for metadata.](https://kometa.wiki/en/latest/config/settings/?h=custom_repo#attributes)**
5. **(Optional) Run [kometa-post-metadata-info.py](/scripts/kometa-post-metadata-info.py)** to seed metadata from your media directories.

See [Detailed Instructions](#detailed-instructions) for step-by-step instructions.

---

## Metadata Automation

Metadata is kept up-to-date automatically when new files are imported via Servarr (Radarr/Sonarr). The workflow is:

1. Radarr/Sonarr imports new media and triggers a webhook.
2. Node-Red processes the webhook and triggers a GitHub Action.
3. The Action updates `movie-metadata.yml` or `show-metadata.yml`.
4. Kometa pulls the latest metadata on its next sync.

---

## Manual Metadata Management

You can manually add metadata using [workflow_dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch) workflows or by editing YAML files directly. Functions are provided for sorting and formatting to ensure consistency.

- **Manual Add Workflow:** Use the "Manually add Media" GitHub Action to insert a new movie/show.

---

## Collections & Playlists

Define and customize your collections and playlists in YAML:

- **Collections:** `movie-collections.yml`, `show-collections.yml`
- **Playlists:** `playlists.yml`

---

## Workflows & Automation

This repo leverages GitHub Actions for:

- Automated metadata updates on webhook/import
- Linting and formatting YAML
- Finding missing posters/genres
- Manual add & sync operations
- Monthly tagging for backup/snapshots

---

## Testing

Shell scripts are tested with [Bats](https://github.com/bats-core/bats-core). See [tests/README.md](/tests/README.md) for structure and how to run tests.

---

## FAQ

**Q: What happens if I lose my Plex server?**  
A: Just restore your repo and point Kometa to it — your metadata, collections, and playlists are preserved!

**Q: Can I add custom fields?**  
A: Yes, but keep YAML structure consistent and update sorting/formatting scripts as needed.

**Q: How do I get alerts for YAML errors?**  
A: Configure the Discord webhook and use the provided linting workflow.

---

## Links & Resources

- [Kometa Documentation](https://kometa.wiki/en/latest/)
- [Plex Media Server](https://www.plex.tv/)
- [Node-Red](https://nodered.org/)
- [Sonarr](https://sonarr.tv/)
- [Radarr](https://radarr.video/)
- [Bats Core](https://github.com/bats-core/bats-core)

---

## Detailed Instructions
*The general workflow looks like the following diagram.*
<img width="1361" height="251" alt="kometa-configs-management" src="https://github.com/user-attachments/assets/c658f546-0827-41dc-a660-50c5dc7a43e9" />

1. Fork this Repository.
2. Generate a GitHub Fine-Grained Personal Access Token with Read and Write access to contents on your fork, save it for later.
3. Create a workflow in your node-red instance by importing "[metadata-update-flow.json](/node-red/metadata-update-flow.json)"
4. Add your GitHub token created in step 2 [here](https://github.com/ChaseRoohms/kometa-configs/blob/06ef596be02c4436bd1d42eebd6d01d64002a5fe/node-red/metadata-update-flow.json#L140).
5. Replace chase-roohms with your GitHub username or organization [here](https://github.com/chase-roohms/kometa-configs/blob/main/node-red/metadata-update-flow.json#L128)
6. In your starr apps create a webhook (Settings -> Connect -> Add Connection -> Webhook) to run only "On File Import", it should POST to the endpoint `http://<NODE_RED_IP>:<NODE_RED_PORT>/arr-import`
7. Point your kometa config to pull metadata from your fork (check the [docs](https://kometa.wiki/en/latest/config/settings/?h=custom_repo#attributes)), and optionally you can keep your collections and playlist configuration here as well.
8. OPTIONAL: To do a one time update of the files based on your movie and show directory folder names you can use [kometa-post-metadata-info.py](/scripts/kometa-post-metadata-info.py), but make sure you replace the values at the top of the script, and your folders / media should all be named according to the trash guides naming schemes for [movies](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/) and [shows](https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/)
9. OPTIONAL: [lint-and-alert.yml](/.github/workflows/lint-and-alert.yml) runs on every push, and will alert you via Discord if you introduce erroneous yaml files. If you want this functionality create a repository secret with the name "DISCORD_WEBHOOK_URL", otherwise, edit [lint-and-alert.yml](/.github/workflows/lint-and-alert.yml) and remove the [alert step](https://github.com/chase-roohms/kometa-configs/blob/main/.github/workflows/lint-and-alert.yml#L61C7-L101C31) and the [DISCORD_WEBHOOK_URL](https://github.com/chase-roohms/kometa-configs/blob/main/.github/workflows/lint-and-alert.yml#L13C1-L13C58) environment variable.
</br>
<p align="center">
  <img width="500" alt="Screenshot of a discord alert representing yaml lint errors" src="https://github.com/user-attachments/assets/1dc79945-8a62-4f14-a1f6-c58d2741b20b" />
  </br>
  <i>Example Discord alert</i>
</p>

