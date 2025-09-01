"""
Plex Collection Poster Mapping Analyzer

This script analyzes Plex media collections and compares them against TMDB (The Movie Database)
collection poster mappings to identify missing poster configurations. It's designed to work
with Kometa (formerly PMM - Plex Meta Manager) configurations to help maintain comprehensive
collection poster coverage.

Purpose:
- Connects to a Plex server and extracts franchise collections for movies and TV shows
- Reads poster mapping configurations from config.yml
- Compares Plex collections against configured TMDB poster mappings
- Generates markdown reports of missing collection posters for easy review
- Provides statistics on collection coverage

Dependencies:
- plexapi: For connecting to and querying Plex server
- tmdbsimple: For querying The Movie Database API
- PyYAML: For reading configuration files
- requests: For HTTP exception handling

Configuration:
Requires a config.yml file containing url_poster_mappings with franchise_movie_posters
and franchise_show_posters sections mapping TMDB collection IDs to poster URLs.

Output:
- missing_movie_collections.md: List of movie collections lacking poster configs
- missing_show_collections.md: List of TV show collections lacking poster configs
- Console statistics showing collection counts and missing poster counts

Usage: python plex.py <plex_url> <plex_token> <tmdb_api_token>

Example: python plex.py http://localhost:32400 abc123token def456apikey
"""

##################################################################
#                                                                #
# Usage: python plex.py <plex_url> <plex_token> <tmdb_api_token> #
#                                                                #
##################################################################

import yaml
import tmdbsimple as tmdb
import requests.exceptions as req_exc
from plexapi.server import PlexServer
from urllib.parse import quote_plus
import sys

# Collections to exclude from analysis - these are typically managed differently
# or don't require custom poster mappings
bypass_collections = [
    # Universes - Often have custom artwork that doesn't map to TMDB collections
    'Alien / Predator',
    # Studios - Use studio branding rather than collection-specific posters
    'A24',
    'Illumination Entertainment',
    'DreamWorks Studios',
    'Marvel Studios',
    'Pixar',
    # Charts - Dynamic collections that use algorithmic posters
    'Plex Popular',
    'IMDb Popular',
    'IMDb Top 250'
]

# Mapping to fix discrepancies between Kometa collection names and TMDB collection names
# This ensures proper matching when collection titles don't exactly align
name_replacements = {
    '28 Days/Weeks Later': '28 Days/Weeks/Years Later',
    'Godzilla (MonsterVerse)': 'Godzilla',
    'Berserk: Golden Age Arc': 'Berserk: The Golden Age Arc'
}

def get_plex_franchise_collections(section: str) -> set:
    """
    Extract franchise collection names from a Plex library section.
    
    Filters out collections that end with common suffixes like 'Movies', 'Universe',
    'Series', 'Shows' as these are typically auto-generated or studio collections
    rather than true franchise collections that need custom poster mappings.
    
    Args:
        section (str): The type of section to process ('movie' or 'show')
        
    Returns:
        set: A set of filtered collection names with name replacements applied
        
    Raises:
        ValueError: If section is not 'movie' or 'show'
    """
    match section:
        case "movie":
            sec_no = 0  # Movies are typically the first section in Plex
        case "show":
            sec_no = 1  # TV Shows are typically the second section
        case _:
            raise ValueError(f"Unknown section: {section}")
    
    # Get all collections from the specified Plex library section
    plex_collections = set([item.title for item in plex_sections[sec_no].collections()])
    temp = set()
    
    # Filter collections to only include franchise-type collections
    for collection in plex_collections:
        if (not collection.endswith(' Movies') and
        not collection.endswith(' Universe') and
        not collection.endswith(' Series') and
        not collection.endswith(' Shows') and
        collection not in bypass_collections):
            # Apply name replacements to standardize collection names for TMDB matching
            temp.add(name_replacements.get(collection, collection))
    return temp

def get_tmdb_collection_title(type: str, id: int) -> str:
    """
    Retrieve the collection title from TMDB using the collection ID.
    
    Cleans up the title by removing common suffixes like '- Collection' and 'Collection'
    to match how these collections might be named in Plex.
    
    Args:
        type (str): The media type ('movie' or 'show')
        id (int): The TMDB collection ID
        
    Returns:
        str: The cleaned collection title
        
    Raises:
        Exception: If the collection ID is not found or other errors occur
    """
    try:
        match type:
            case "movie":
                collection = tmdb.Collections(id)  # Use TMDB Collections API for movies
            case "show":
                collection = tmdb.TV(id)  # Use TMDB TV API for shows
            case _:
                raise Exception(f"Unknown type: {type}")
    except req_exc.HTTPError:
        raise Exception(f"Could not find {id}")
    except Exception as e:
        raise Exception(f"Error occurred: {e}")
    
    # Clean up the collection name by removing common TMDB suffixes
    return (collection.info()
                      .get('name')
                      .replace(' - Collection', '')
                      .replace('Collection', '')
                      .strip())

def get_tmdb_collections_from_config(config, poster_type: str, media_type: str) -> set:
    """
    Extract TMDB collection titles from config for given poster_type and media_type.
    
    Parses the configuration file to extract TMDB collection IDs from poster mappings,
    then fetches the actual collection titles from TMDB API for comparison with Plex.
    
    Args:
        config: The loaded YAML configuration containing poster mappings
        poster_type (str): 'franchise_movie_posters' or 'franchise_show_posters'
        media_type (str): 'movie' or 'show'
        
    Returns:
        tuple: A set of TMDB collection titles and a dict mapping titles to IDs
    """
    tmdb_collections = set()
    tmdb_titles_to_id = dict()
    
    # Process each poster mapping in the configuration
    for url_poster in config['url_poster_mappings'][poster_type].keys():
        try:
            # Extract TMDB collection ID from the poster mapping key
            collection_id = int(url_poster.replace('url_poster_', ''))
            print(f"Grabbing TMDB collection {collection_id}")
            
            # Fetch the actual collection title from TMDB
            title = get_tmdb_collection_title(media_type, collection_id)
            tmdb_collections.add(title)
            tmdb_titles_to_id[title] = collection_id
        except ValueError:
            raise Exception(f"Skipping {url_poster}, not a tmdb_id")
        except Exception as e:
            print(e)
    return tmdb_collections, tmdb_titles_to_id

def write_missing_md_report(missing_collections: set, media_type: str, titles_to_id: dict):
    """
    Generate a markdown report of missing collection poster mappings.
    
    Creates a markdown file listing all collections that exist in Plex but don't have
    corresponding poster mappings in the configuration. Each entry includes a search
    link to TMDB to make it easy to find and add the missing collection.
    
    Args:
        missing_collections (set): Set of collection names missing poster mappings
        media_type (str): 'movie' or 'show' - used for filename generation
        titles_to_id (dict): Mapping of collection titles to TMDB IDs (currently unused)
    """
    if len(missing_collections) == 0:
        return
    
    # TMDB search URL base for generating clickable links
    url_base = "https://www.themoviedb.org/search?query="
    
    with open(f'missing_{media_type}_collections.md', 'w') as file:
        for collection in sorted(missing_collections):
            # URL-encode the collection name for the search query
            safe_collection = quote_plus(f'{collection} Collection')
            file.write(f"- [{collection}]({url_base}{safe_collection})\n")


if __name__ == "__main__":
    # Validate command line arguments
    if len(sys.argv) != 4:
        print("Usage: python plex.py <plex_url> <plex_token> <tmdb_api_token>")
        sys.exit(1)

    # Parse command line arguments
    baseurl = sys.argv[1]      # Plex server URL (e.g., http://localhost:32400)
    token = sys.argv[2]        # Plex authentication token
    tmdb.API_KEY = sys.argv[3] # TMDB API key for collection lookups

    # Connect to Plex server and get library sections
    plex = PlexServer(baseurl, token)
    plex_sections = plex.library.sections()
    
    # Extract franchise collections from Plex for both movies and TV shows
    plex_movie_collections = get_plex_franchise_collections("movie")
    plex_show_collections = get_plex_franchise_collections("show")

    # Load poster mapping configuration from YAML file
    with open('config.yml', 'r') as file:
        config = yaml.safe_load(file)

    # Get TMDB collections that have poster mappings configured
    tmdb_movie_collections, tmdb_movies_to_id = get_tmdb_collections_from_config(config, 'franchise_movie_posters', 'movie')
    tmdb_show_collections, tmdb_shows_to_id = get_tmdb_collections_from_config(config, 'franchise_show_posters', 'show')

    # Find collections that exist in Plex but don't have poster mappings
    missing_movie_collections = plex_movie_collections - tmdb_movie_collections
    missing_show_collections = plex_show_collections - tmdb_show_collections
    
    # Generate markdown reports for missing poster mappings
    write_missing_md_report(missing_movie_collections, "movie", tmdb_movies_to_id)
    write_missing_md_report(missing_show_collections, "show", tmdb_shows_to_id)

    # Print summary statistics
    print()
    print()
    print(f'{len(plex_movie_collections)} Plex Movie Collections Found')
    print(f'{len(plex_show_collections)} Plex Show Collections Found')
    print(f'{len(tmdb_movie_collections)} TMDB Movie Collections Found')
    print(f'{len(tmdb_show_collections)} TMDB Show Collections Found')
    print(f'{(len(missing_movie_collections) + len(missing_show_collections))} Missing Collections Posters Found')

