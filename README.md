# Kometa Configs

This repository contains a collection of configuration files for use with **Kometa**, designed to manage metadata, playlists, collections, and more for your Plex instance.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)

## Overview
The **Kometa Configs** repository serves as a centralized source for managing and organizing Plex metadata, playlists, and collections. These configurations are tailored to streamline the experience of maintaining a Plex library, ensuring that my media is consistently organized and up-to-date. This data is pulled by the Kometa application and used to udate the metadata of media on my Plex server.

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

1. In your starr apps create a webhook (Settings -> Connect -> Add Connection -> Webhook) to run only "On File Import"
2. Create a workflow in your node-red instance by importing ""
3. Replace the GitHub token with a Fine-Grained Personal Access Token with
