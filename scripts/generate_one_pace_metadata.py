#!/usr/bin/env python3
"""
Generate One Pace metadata YAML structure from CSV files.

This script reads CSV files from data/one-pace/csvs/ and generates
YAML metadata entries for each arc (season) with its episodes.
"""

import argparse
import csv
import sys
from pathlib import Path
import re
import yaml
from collections import OrderedDict


# Constants
APOSTROPHE_CHARS = ["'", "'", "`"]
SUFFIX_PATTERNS_TO_REMOVE = r'\s*\((TBR|WIP)\)\s*$'


def normalize_arc_name(arc_name: str, remove_apostrophes: bool = True) -> str:
    """
    Normalize arc name by removing apostrophes and special characters.
    
    Args:
        arc_name: The arc name to normalize
        remove_apostrophes: Whether to remove apostrophe characters
        
    Returns:
        Normalized arc name
    """
    if remove_apostrophes:
        for char in APOSTROPHE_CHARS:
            arc_name = arc_name.replace(char, "")
    return arc_name


def normalize_range(text: str) -> str:
    """
    Normalize episode/chapter ranges to have consistent spacing.
    - Adds spaces around hyphens: "40-41" -> "40 - 41"
    - Ensures space after commas: "42,22" -> "42, 22"
    
    Args:
        text: Text containing ranges
        
    Returns:
        Text with normalized spacing
    """
    if not text:
        return ''
    
    # First ensure space after commas
    text = re.sub(r',\s*', ', ', text)
    
    # Add spaces around hyphens that are between numbers
    # This pattern looks for digit-hyphen-digit and adds spaces
    text = re.sub(r'(\d)\s*-\s*(\d)', r'\1 - \2', text)
    
    return text


def clean_field(text: str) -> str:
    """
    Clean up CSV field by removing newlines and prefixes.
    
    Args:
        text: Raw text from CSV
        
    Returns:
        Cleaned text without newlines and prefixes
    """
    if not text:
        return ''
    
    # Remove newlines and extra whitespace
    text = ' '.join(text.split())
    
    # Remove "Ch. " prefix (only when it's at the start or after a comma/space)
    text = re.sub(r'(?:^|(?<=,\s))Ch\.\s*', '', text)
    
    # Remove "Ep. " prefix (only when it's at the start or after a comma/space)
    text = re.sub(r'(?:^|(?<=,\s))Ep\.\s*', '', text)
    
    # Normalize ranges (add spaces around hyphens and after commas)
    text = normalize_range(text)
    
    return text.strip()


def format_episode_title(one_pace_title: str, arc_name: str, episode_num: int, anime_episodes: str) -> str:
    """
    Format episode title to use "Pt. X (anime episodes)" instead of numbers.
    
    Args:
        one_pace_title: Original title from CSV (e.g., "Romance Dawn 01")
        arc_name: Name of the arc
        episode_num: Episode number
        anime_episodes: Anime episodes covered
        
    Returns:
        Formatted title (e.g., "Romance Dawn Pt. 1 (1 - 3, 19)")
    """
    # Normalize the anime_episodes to ensure consistent spacing
    anime_episodes = normalize_range(anime_episodes)
    
    # If the title already has the arc name and ends with a number pattern
    # Replace patterns like "01", "02", etc. with "Pt. X (episodes)"
    pattern = rf'^{re.escape(arc_name)}\s+(\d+)$'
    match = re.match(pattern, one_pace_title)
    
    if match:
        # Extract the number and convert it to "Pt. X (episodes)" format
        num = int(match.group(1))
        if anime_episodes:
            return f"{arc_name} Pt. {num} ({anime_episodes})"
        else:
            return f"{arc_name} Pt. {num}"
    
    # If it doesn't match the expected pattern, return as-is with episodes if available
    if anime_episodes:
        return f"{one_pace_title} ({anime_episodes})"
    return one_pace_title


def get_episode_range(episodes_dict: dict) -> tuple:
    """
    Get the range of anime episodes and manga chapters from all episodes.
    
    Args:
        episodes_dict: Dictionary of episodes with their data
        
    Returns:
        Tuple of (anime_range, manga_range) as strings
    """
    all_anime = []
    all_manga = []
    
    for ep_data in episodes_dict.values():
        anime_eps = ep_data.get('anime_episodes', '')
        manga_chaps = ep_data.get('manga_chapters', '')
        
        if anime_eps:
            all_anime.append(anime_eps)
        if manga_chaps:
            all_manga.append(manga_chaps)
    
    # Extract numbers from the episode/chapter strings
    def extract_numbers(text_list):
        numbers = []
        for text in text_list:
            # Find all numbers in the text (excluding text like "Episode of")
            matches = re.findall(r'\d+', text)
            numbers.extend([int(m) for m in matches])
        return numbers
    
    anime_numbers = extract_numbers(all_anime)
    manga_numbers = extract_numbers(all_manga)
    
    if anime_numbers:
        anime_range = f"{min(anime_numbers)}-{max(anime_numbers)}"
    else:
        anime_range = ""
    
    if manga_numbers:
        manga_range = f"{min(manga_numbers)}-{max(manga_numbers)}"
    else:
        manga_range = ""
    
    return anime_range, manga_range


def parse_csv_file(csv_path: Path) -> dict:
    """
    Parse a One Pace CSV file and extract episode information.
    
    Args:
        csv_path: Path to the CSV file
        
    Returns:
        Dictionary with arc information and episodes
    """
    arc_name = csv_path.stem  # Filename without extension
    episodes = {}
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        episode_num = 1
        for row in reader:
            # Skip empty rows - handle both 'One Pace Episode' and ' One Pace Episode' (with leading space)
            # This handles potential inconsistencies in CSV headers
            one_pace_ep_key = 'One Pace Episode' if 'One Pace Episode' in row else ' One Pace Episode'
            if not row.get(one_pace_ep_key):
                continue
                
            # Extract and clean episode information
            one_pace_ep = row.get(one_pace_ep_key, '').strip()
            
            # Skip episodes with "Forward" in the title (unreleased episodes)
            if 'Forward' in one_pace_ep:
                continue
            
            chapters = clean_field(row.get('Chapters', ''))
            anime_episodes = clean_field(row.get('Episodes', ''))
            
            if one_pace_ep:
                # Format the episode title with anime episodes
                formatted_title = format_episode_title(one_pace_ep, arc_name, episode_num, anime_episodes)
                episode_data = {'title': formatted_title}
                
                # Build episode summary
                summary_parts = []
                if anime_episodes:
                    episode_data['anime_episodes'] = anime_episodes
                    summary_parts.append(f"Covers anime episode(s): {anime_episodes}")
                
                if chapters:
                    episode_data['manga_chapters'] = chapters
                    summary_parts.append(f"Covers manga chapter(s): {chapters}")
                
                if summary_parts:
                    episode_data['summary'] = '\n'.join(summary_parts)
                
                episodes[episode_num] = episode_data
                episode_num += 1
    
    return {
        'arc_name': arc_name,
        'episodes': episodes
    }


def load_existing_metadata(metadata_file: Path) -> dict:
    """
    Load parent-level metadata from existing one-pace.yml file.
    
    Args:
        metadata_file: Path to existing metadata YAML file
        
    Returns:
        Dictionary with parent metadata (without seasons)
    """
    if not metadata_file.exists():
        print(f"Warning: Existing metadata file not found at {metadata_file}", file=sys.stderr)
        print("Using default metadata values", file=sys.stderr)
        return {}
    
    try:
        with open(metadata_file, 'r', encoding='utf-8') as f:
            existing = yaml.safe_load(f)
            
        if existing and 'metadata' in existing and 'One Pace' in existing['metadata']:
            parent_metadata = existing['metadata']['One Pace'].copy()
            # Remove seasons since we'll be regenerating them
            parent_metadata.pop('seasons', None)
            return parent_metadata
    except Exception as e:
        print(f"Warning: Could not read existing metadata: {e}", file=sys.stderr)
        print("Using default metadata values", file=sys.stderr)
    
    return {}


def load_arc_summaries(summaries_file: Path) -> dict:
    """
    Load arc summaries from summaries.yml file.
    
    Args:
        summaries_file: Path to summaries YAML file
        
    Returns:
        Dictionary mapping arc names to their summaries
    """
    if not summaries_file.exists():
        print(f"Warning: Summaries file not found at {summaries_file}", file=sys.stderr)
        return {}
    
    try:
        with open(summaries_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
            
        if data and 'arcs' in data:
            # Return a dict mapping arc names to summaries
            return {arc_name: arc_data.get('summary', '') 
                    for arc_name, arc_data in data['arcs'].items()}
    except Exception as e:
        print(f"Warning: Could not read summaries file: {e}", file=sys.stderr)
    
    return {}


def load_saga_data(sagas_file: Path) -> dict:
    """
    Load saga information from sagas.yml file.
    
    Args:
        sagas_file: Path to sagas YAML file
        
    Returns:
        Dictionary mapping arc names to their saga information (name and background URL)
    """
    if not sagas_file.exists():
        print(f"Warning: Sagas file not found at {sagas_file}", file=sys.stderr)
        return {}
    
    try:
        with open(sagas_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
            
        if not data or 'sagas' not in data:
            return {}
        
        # Build a mapping of arc_name -> (saga_name, saga_background_url)
        arc_to_saga = {}
        for saga_name, saga_data in data['sagas'].items():
            url_background = saga_data.get('url_background', '')
            arcs = saga_data.get('arcs', [])
            
            for arc_name in arcs:
                arc_to_saga[arc_name] = {
                    'saga_name': saga_name,
                    'url_background': url_background
                }
        
        return arc_to_saga
    except Exception as e:
        print(f"Warning: Could not read sagas file: {e}", file=sys.stderr)
    
    return {}


def build_metadata_structure(arcs_data: list, start_season: int, existing_metadata_file: Path, summaries_file: Path, sagas_file: Path, arc_overview_data: dict) -> dict:
    """
    Build the complete metadata structure as a dictionary.
    
    Args:
        arcs_data: List of tuples (arc_name, episodes_dict)
        start_season: Starting season number
        existing_metadata_file: Path to existing metadata file to pull parent metadata from
        summaries_file: Path to summaries YAML file
        sagas_file: Path to sagas YAML file
        arc_overview_data: Dictionary of arc data from Arc Overview.csv
        
    Returns:
        Dictionary representing the complete YAML structure
    """
    # Load arc summaries and saga data
    arc_summaries = load_arc_summaries(summaries_file)
    arc_to_saga = load_saga_data(sagas_file)
    
    seasons = {}
    
    for season_num, (arc_name, episodes) in enumerate(arcs_data, start=start_season):
        # Try to find the summary for this arc
        # Remove "(WIP)" suffix when looking up summary
        lookup_name = re.sub(SUFFIX_PATTERNS_TO_REMOVE, '', arc_name)
        
        # Normalize apostrophes for lookup (remove them)
        lookup_name_normalized = normalize_arc_name(lookup_name)
        
        # Try exact match first, then normalized match, then try without trailing 's'
        arc_summary = arc_summaries.get(lookup_name)
        if not arc_summary:
            arc_summary = arc_summaries.get(lookup_name_normalized)
        if not arc_summary and lookup_name_normalized.endswith('s'):
            # Try without the trailing 's' (e.g., "Straw Hats" -> "Straw Hat")
            arc_summary = arc_summaries.get(lookup_name_normalized[:-1])
        
        # Get episode/chapter ranges from Arc Overview if available
        overview_info = arc_overview_data.get(arc_name, {})
        anime_range = normalize_range(overview_info.get('anime_episodes', ''))
        manga_range = normalize_range(overview_info.get('manga_chapters', ''))
        
        # If not in overview, fall back to calculating from episodes
        if not anime_range or not manga_range:
            calculated_anime, calculated_manga = get_episode_range(episodes)
            if not anime_range:
                anime_range = calculated_anime
            if not manga_range:
                manga_range = calculated_manga
        
        # Build season summary
        summary_parts = []
        if arc_summary:
            summary_parts.append(arc_summary)
        else:
            # Fallback to default format if no summary found
            summary_parts.append(f'The {arc_name} Arc')
        
        if anime_range:
            summary_parts.append(f'Covers anime episode(s): {anime_range}')
        if manga_range:
            summary_parts.append(f'Covers manga chapter(s): {manga_range}')
        
        # Build season metadata with keys in desired order:
        # title, url_poster, url_background, saga, summary, episodes
        season_metadata = OrderedDict()
        season_metadata['title'] = arc_name
        season_metadata['url_poster'] = f'https://raw.githubusercontent.com/chase-roohms/kometa-configs/main/assets/one-pace/seasons/{season_num}.png'
        
        # Add saga information if available
        # Try to find saga info using the same lookup variations as summaries
        saga_info = arc_to_saga.get(lookup_name)
        if not saga_info:
            saga_info = arc_to_saga.get(lookup_name_normalized)
        if not saga_info and lookup_name_normalized.endswith('s'):
            saga_info = arc_to_saga.get(lookup_name_normalized[:-1])
        
        # Add url_background and saga in the correct order
        if saga_info:
            if saga_info['url_background']:
                season_metadata['url_background'] = saga_info['url_background']
            season_metadata['saga'] = saga_info['saga_name']
        
        # Add summary and episodes last
        season_metadata['summary'] = '\n'.join(summary_parts)
        season_metadata['episodes'] = episodes
        
        seasons[season_num] = season_metadata
    
    # Load parent metadata from existing file
    parent_metadata = load_existing_metadata(existing_metadata_file)
    
    # If we couldn't load existing metadata, use defaults
    if not parent_metadata:
        parent_metadata = {
            'match': {
                'title': 'One Pace'
            },
            'label_title': 'One Pace',
            'sort_title': 'One Pace',
            'original_title': 'One Piece',
            'use_original_title': 'no',
            'release_year': '2013',
            'url_poster': 'https://raw.githubusercontent.com/chase-roohms/kometa-configs/main/assets/one-pace/parent.png',
            'url_background': 'https://raw.githubusercontent.com/chase-roohms/kometa-configs/main/assets/one-pace/background.png',
            'url_logo': 'https://raw.githubusercontent.com/chase-roohms/kometa-configs/main/assets/one-pace/logo.png',
            'studio': 'Toei Animation',
            'audio_language': 'ja-JP',
            'tagline': 'The dreams of pirates will never end!',
            'summary': 'One Pace is a fan project that recuts the One Piece anime in an attempt '
                      'to make the anime pacing more bearable. The team accomplishes this by removing '
                      'filler scenes not present in the source material. This process requires meticulous '
                      'editing and quality control to ensure seamless music and transitions. One Pace '
                      'includes everything that is in the manga, plus a little bit of anime only content '
                      'where it is appropriate.',
            'genre.sync': ['Anime']
        }
    
    # Add the seasons to the parent metadata
    parent_metadata['seasons'] = seasons
    
    metadata = {
        'metadata': {
            'One Pace': parent_metadata
        }
    }
    
    return metadata


def get_arc_order(csv_dir: Path) -> dict:
    """
    Get the ordered list of arcs from Arc Overview.csv along with their episode/chapter ranges.
    
    Args:
        csv_dir: Directory containing CSV files
        
    Returns:
        Dictionary mapping arc names to their anime episode and manga chapter ranges
    """
    overview_path = csv_dir / "Arc Overview.csv"
    arc_data = {}
    
    if overview_path.exists():
        with open(overview_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                arc_name = row.get('Arcs', '').strip()
                # Skip the "Totals" row - it's a summary row, not an arc
                if arc_name and arc_name != 'Totals':
                    anime_episodes = row.get('Anime Episodes', '').strip()
                    manga_chapters = row.get('Manga Chapters', '').strip()
                    arc_data[arc_name] = {
                        'anime_episodes': anime_episodes,
                        'manga_chapters': manga_chapters
                    }
    
    return arc_data


def find_csv_file(csv_dir: Path, arc_name: str) -> Path:
    """
    Find the CSV file for a given arc name, trying multiple variations.
    
    This handles cases where arc names may have different apostrophes, suffixes,
    or pluralization differences.
    
    Args:
        csv_dir: Directory containing CSV files
        arc_name: Name of the arc to find
        
    Returns:
        Path to the CSV file
        
    Raises:
        FileNotFoundError: If no matching CSV file is found
    """
    # Remove both (TBR) and (WIP) suffixes when looking for CSV files
    csv_arc_name = re.sub(SUFFIX_PATTERNS_TO_REMOVE, '', arc_name)
    
    # Normalize different types of apostrophes and quotes
    csv_arc_name_normalized = normalize_arc_name(csv_arc_name)
    
    # Try multiple variations to find the CSV file
    variations = [csv_arc_name, csv_arc_name_normalized]
    
    # Try without trailing 's' (e.g., "Straw Hats" -> "Straw Hat")
    if csv_arc_name_normalized.endswith('s'):
        csv_arc_name_singular = csv_arc_name_normalized[:-1]
        variations.append(csv_arc_name_singular)
    
    for variation in variations:
        csv_path = csv_dir / f"{variation}.csv"
        if csv_path.exists():
            return csv_path
    
    # If we get here, no file was found
    error_msg = f"CSV file not found for arc '{arc_name}'\n"
    error_msg += f"  Tried: {', '.join(f'{v}.csv' for v in variations)}"
    raise FileNotFoundError(error_msg)


def configure_yaml_multiline_strings():
    """
    Configure PyYAML to use literal style for multiline strings.
    
    This preserves newlines without blank lines, making the output more readable.
    Also configures OrderedDict to be represented as regular YAML mappings.
    """
    def str_representer(dumper, data):
        if '\n' in data:
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
        return dumper.represent_scalar('tag:yaml.org,2002:str', data)
    
    def ordered_dict_representer(dumper, data):
        return dumper.represent_mapping('tag:yaml.org,2002:map', data.items())
    
    yaml.add_representer(str, str_representer)
    yaml.add_representer(OrderedDict, ordered_dict_representer)


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Generate One Pace metadata YAML from CSV files"
    )
    parser.add_argument(
        "--csv-dir",
        default="data/one-pace/csvs",
        help="Directory containing CSV files (default: data/one-pace/csvs)"
    )
    parser.add_argument(
        "--output",
        default="metadata/one-pace.yml",
        help="Output YAML file (default: metadata/one-pace.yml)"
    )
    parser.add_argument(
        "--start-season",
        type=int,
        default=1,
        help="Starting season number (default: 1)"
    )
    parser.add_argument(
        "--summaries",
        default="data/one-pace/summaries.yml",
        help="Summaries YAML file (default: data/one-pace/summaries.yml)"
    )
    parser.add_argument(
        "--sagas",
        default="data/one-pace/sagas.yml",
        help="Sagas YAML file (default: data/one-pace/sagas.yml)"
    )
    
    args = parser.parse_args()
    
    csv_dir = Path(args.csv_dir)
    
    if not csv_dir.exists():
        print(f"Error: CSV directory not found: {csv_dir}", file=sys.stderr)
        sys.exit(1)
    
    # Get arc data from Arc Overview
    arc_overview_data = get_arc_order(csv_dir)
    
    if not arc_overview_data:
        print("Warning: Could not read Arc Overview.csv, using alphabetical order", file=sys.stderr)
        # Fallback to all CSV files except Arc Overview
        csv_files = [f for f in csv_dir.glob("*.csv") if f.stem != "Arc Overview"]
        arc_order = [f.stem for f in sorted(csv_files)]
    else:
        arc_order = list(arc_overview_data.keys())
    
    arcs_data = []
    
    # Process each arc in order
    for arc_name in arc_order:
        try:
            csv_path = find_csv_file(csv_dir, arc_name)
        except FileNotFoundError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        
        print(f"Processing: {arc_name}")
        
        arc_data = parse_csv_file(csv_path)
        
        if not arc_data['episodes']:
            print(f"  Warning: No episodes found in {arc_name}, skipping", file=sys.stderr)
            continue
        
        # Remove (TBR) from arc name for metadata, but keep (WIP)
        clean_arc_name = re.sub(r'\s*\(TBR\)\s*$', '', arc_name)
        arcs_data.append((clean_arc_name, arc_data['episodes']))
        print(f"  ✓ Found {len(arc_data['episodes'])} episodes")
    
    # Determine the source metadata file (use existing output file if it exists)
    output_path = Path(args.output)
    existing_metadata_file = output_path if output_path.exists() else Path("metadata/one-pace.yml")
    summaries_file = Path(args.summaries)
    sagas_file = Path(args.sagas)
    
    # Build the metadata structure
    metadata_structure = build_metadata_structure(arcs_data, args.start_season, existing_metadata_file, summaries_file, sagas_file, arc_overview_data)
    
    # Configure PyYAML to use literal style for multiline strings (preserves newlines without blank lines)
    configure_yaml_multiline_strings()
    
    # Write output using PyYAML
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        # Write the yaml-language-server comment at the top
        f.write('# yaml-language-server: $schema=https://json-schema.org/draft-07/schema\n')
        
        yaml.dump(
            metadata_structure,
            f,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            width=80  # Wrap long lines at 80 characters for readability
        )
    
    print(f"\n✓ Successfully generated metadata for {len(arcs_data)} arcs")
    print(f"  Output written to: {output_path}")


if __name__ == "__main__":
    main()
