# Kometa Configs 

This repository contains a collection of configuration files for use with **Kometa**, designed to manage metadata, playlists, collections, and more for a Plex instance.

Metadata files are auto updated with new entries when files are imported via the [servarr apps](https://wiki.servarr.com/).

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)

## Overview
The **Kometa Configs** repository serves as a centralized source for managing and organizing Plex metadata, playlists, and collections. These configurations provide "metadata as code", ensuring that my media is consistently organized and that customization is retained even if my server goes down or my library is lsot. This data is pulled by the Kometa application and used to udate of media, playlists and collections on my Plex server.

## Features
- **Metadata Management**: Easily customize and organize metadata for my Plex library.
- **Playlists & Collections**: Create and manage playlists and collections to enhance my Plex experience.
- **Automated Updates**: Metadata automatically added when media is imported via the [servarr apps](https://wiki.servarr.com/) (specifically Radarr and Sonarr).

## Prerequisites
- **Kometa**: Ensure that the Kometa tool is installed and set up correctly.
- **Plex Media Server**: A working Plex Media Server instance.
- **Sonarr or Radarr**: Media managers that will trigger a Node-Red workflow via webhook.
- **Node-Red**: Middle man to make the servarr app's webhooks compatible with GitHub Actions

## Usage
*The general workflow looks like the following diagram.*
<img width="1361" height="251" alt="kometa-configs-management" src="https://github.com/user-attachments/assets/c658f546-0827-41dc-a660-50c5dc7a43e9" />

1. Fork this Repository.
2. Generate a GitHub Fine-Grained Personal Access Token with Read and Write access to contents on your fork, save it for later.
3. Create a workflow in your node-red instance by importing "[metadata-update-flow.json](/node-red/metadata-update-flow.json)"
4. Add your GitHub token created in step 2 [here](https://github.com/ChaseRoohms/kometa-configs/blob/06ef596be02c4436bd1d42eebd6d01d64002a5fe/node-red/metadata-update-flow.json#L140).
5. In your starr apps create a webhook (Settings -> Connect -> Add Connection -> Webhook) to run only "On File Import", it should POST to the endpoint `http://<NODE_RED_IP>:<NODE_RED_PORT>/arr-import`
6. Point your kometa config to pull metadata from your fork (check the [docs](https://kometa.wiki/en/latest/config/settings/?h=custom_repo#attributes)), and optionally you can keep your collections and playlist configuration here as well.
7. OPTIONAL: To do a one time update of the files based on your movie and show directory folder names you can use [kometa-post-metadata-info.py](/scripts/kometa-post-metadata-info.py), but make sure you replace the values at the top of the script, and your folders / media should all be named according to the trash guides naming schemes for [movies](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/) and [shows](https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/)
8. OPTIONAL: [lint-and-alert.yml](/.github/workflows/lint-and-alert.yml) runs on every push, and will alert you via Discord if you introduce erroneous yaml files. If you want this functionality create a repository secret with the name "DISCORD_WEBHOOK_URL", otherwise, edit [lint-and-alert.yml](/.github/workflows/lint-and-alert.yml) and remove the [alert step](https://github.com/chase-roohms/kometa-configs/blob/main/.github/workflows/lint-and-alert.yml#L61C7-L101C31) and the [DISCORD_WEBHOOK_URL](https://github.com/chase-roohms/kometa-configs/blob/main/.github/workflows/lint-and-alert.yml#L13C1-L13C58) environment variable.
*Example Discord Alert*
<img width="593" height="233" alt="Screenshot 2025-07-25 at 6 11 15 PM" src="https://github.com/user-attachments/assets/1dc79945-8a62-4f14-a1f6-c58d2741b20b" />

