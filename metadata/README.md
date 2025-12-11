# Metadata File Notes
## Folder Usage
This folder is for metadata of abnormal or extensive collections / series. **Most** shows and movies should go in [movie-metadata.yml](/movie-metadata.yml) and [show-metadata.yml](/show-metadata.yml) respectively. However for a show like One Pace with 36 seasons where each episode title defined as code - individual files like [one-pace.yml](/metadata/one-pace.yml) should be used instead for legability.

### `url_logo`
For some reason there is sometimes an issue applying this, and you will get a critical `no such table: image_map_2_logos` error. In those cases, delete the config.cache file in the config directory, and rerun Kometa.

### `url_theme`
Not actually supported by Kometa, but you can run `wget` on this url and add it to your main show directory for Plex to add the One Piece theme song. Note: it MUST be named `theme.mp3`
