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
    
    # Ensure space after commas
    text = re.sub(r',\s*', ', ', text)
    
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
        Formatted title (e.g., "Romance Dawn Pt. 1 (1-3, 19)")
    """
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


def build_metadata_structure(arcs_data: list, start_season: int) -> dict:
    """
    Build the complete metadata structure as a dictionary.
    
    Args:
        arcs_data: List of tuples (arc_name, episodes_dict)
        start_season: Starting season number
        
    Returns:
        Dictionary representing the complete YAML structure
    """
    seasons = {}
    
    for season_num, (arc_name, episodes) in enumerate(arcs_data, start=start_season):
        # Get episode ranges for the season summary
        anime_range, manga_range = get_episode_range(episodes)
        
        # Build season summary
        summary_parts = [f'The {arc_name} Arc']
        if anime_range:
            summary_parts.append(f'Covers anime episode(s): {anime_range}')
        if manga_range:
            summary_parts.append(f'Covers manga chapter(s): {manga_range}')
        
        seasons[season_num] = {
            'title': arc_name,
            'url_poster': f'https://raw.githubusercontent.com/chase-roohms/kometa-configs/main/posters/one-pace/seasons/{season_num}.png',
            'summary': '\n'.join(summary_parts),
            'episodes': episodes
        }
    
    metadata = {
        'metadata': {
            'One Pace': {
                'match': {
                    'title': 'One Pace'
                },
                'label_title': 'One Pace',
                'sort_title': 'One Pace',
                'release_year': '2013',
                'url_poster': 'https://raw.githubusercontent.com/chase-roohms/kometa-configs/main/posters/one-pace/parent.png',
                'summary': 'One Pace is a fan project that recuts the One Piece anime in an attempt '
                          'to make the anime pacing more bearable. The team accomplishes this by removing '
                          'filler scenes not present in the source material. This process requires meticulous '
                          'editing and quality control to ensure seamless music and transitions. One Pace '
                          'includes everything that is in the manga, plus a little bit of anime only content '
                          'where it is appropriate.',
                'audio_language': 'ja-JP',
                'genre.sync': ['Anime'],
                'seasons': seasons
            }
        }
    }
    
    return metadata


def get_arc_order(csv_dir: Path) -> list:
    """
    Get the ordered list of arcs from Arc Overview.csv.
    
    Args:
        csv_dir: Directory containing CSV files
        
    Returns:
        List of arc names in order
    """
    overview_path = csv_dir / "Arc Overview.csv"
    arc_order = []
    
    if overview_path.exists():
        with open(overview_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                arc_name = row.get('Arcs', '').strip()
                if arc_name:
                    arc_order.append(arc_name)
    
    return arc_order


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
    
    args = parser.parse_args()
    
    csv_dir = Path(args.csv_dir)
    
    if not csv_dir.exists():
        print(f"Error: CSV directory not found: {csv_dir}", file=sys.stderr)
        sys.exit(1)
    
    # Get arc order from Arc Overview
    arc_order = get_arc_order(csv_dir)
    
    if not arc_order:
        print("Warning: Could not read Arc Overview.csv, using alphabetical order", file=sys.stderr)
        # Fallback to all CSV files except Arc Overview
        csv_files = [f for f in csv_dir.glob("*.csv") if f.stem != "Arc Overview"]
        arc_order = [f.stem for f in sorted(csv_files)]
    
    arcs_data = []
    
    # Process each arc in order
    for arc_name in arc_order:
        # Remove both (TBR) and (WIP) suffixes when looking for CSV files
        csv_arc_name = re.sub(r'\s*\((TBR|WIP)\)\s*$', '', arc_name)
        
        # Normalize different types of apostrophes and quotes
        # Remove apostrophes entirely as filenames may not have them
        csv_arc_name_normalized = csv_arc_name.replace("'", "").replace("'", "").replace("`", "")
        
        # Try multiple variations to find the CSV file
        csv_path = csv_dir / f"{csv_arc_name}.csv"
        if not csv_path.exists():
            csv_path = csv_dir / f"{csv_arc_name_normalized}.csv"
        
        # Try without trailing 's' (e.g., "Straw Hats" -> "Straw Hat")
        if not csv_path.exists() and csv_arc_name_normalized.endswith('s'):
            csv_arc_name_singular = csv_arc_name_normalized[:-1]
            csv_path = csv_dir / f"{csv_arc_name_singular}.csv"
        
        if not csv_path.exists():
            print(f"Warning: CSV file not found for arc '{arc_name}', skipping", file=sys.stderr)
            continue
        
        print(f"Processing: {arc_name}")
        
        arc_data = parse_csv_file(csv_path)
        
        if not arc_data['episodes']:
            print(f"  Warning: No episodes found in {arc_name}, skipping", file=sys.stderr)
            continue
        
        # Remove (TBR) from arc name for metadata, but keep (WIP)
        clean_arc_name = re.sub(r'\s*\(TBR\)\s*$', '', arc_name)
        arcs_data.append((clean_arc_name, arc_data['episodes']))
        print(f"  ✓ Found {len(arc_data['episodes'])} episodes")
    
    # Build the metadata structure
    metadata_structure = build_metadata_structure(arcs_data, args.start_season)
    
    # Configure PyYAML to use literal style for multiline strings (preserves newlines without blank lines)
    def str_representer(dumper, data):
        if '\n' in data:
            return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
        return dumper.represent_scalar('tag:yaml.org,2002:str', data)
    
    yaml.add_representer(str, str_representer)
    
    # Write output using PyYAML
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
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
