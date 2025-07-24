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
