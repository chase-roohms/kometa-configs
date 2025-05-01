import json
import re
import yaml
import os

from argparse import ArgumentParser, ArgumentTypeError
from unidecode import unidecode
from pprint import pp


def file_path(path_str):
    if os.path.isfile(path_str):
        return path_str
    else:
        raise ArgumentTypeError(f'File not found: {path_str}')


def json_string(json_string):
    if json.loads(json_string):
        return json_string
    else:
        raise ArgumentTypeError('Provided data is not a valid json string')


def get_existing_metadata(filename: str) -> dict:
    '''
    Retrieves the metadata saved in "filename"
    '''
    if not filename.endswith('.yml') and not filename.endswith('.yaml'):
        raise Exception('Function "get_existing_metadata" requires filename to be a yaml file ending in ".yml" or ".yaml"')
    with open(filename, 'r') as metadata_file:
        return yaml.safe_load(metadata_file)['metadata']


def zero_pad(text, width=6):
    '''
    Zero pads any numbers in the string "text" to be at least 6 digits long
    '''
    return re.sub(r'\d+', lambda x: x.group(0).zfill(width), text)


def get_sort_title(title: str) -> str:
    '''
    Converts a title into a title suitable for sorting
    '''
    sort_title = title
    articles = {'a ', 'an ', 'the '}
    for article in articles:
        if sort_title.lower().startswith(article):
            sort_title = sort_title[len(article):]
            break
    return unidecode(sort_title)


def get_media_dict(label_title: str, release_year: int, sort_title: str, additional_data: dict = {}) -> dict[str, str]:
    media_dict                      = dict()
    media_dict['label_title']       = label_title
    media_dict['release_year']      = release_year
    media_dict['sort_title']        = sort_title
    if 'url_poster' not in media_dict:
        media_dict['url_poster']    = ''
    for key, value in additional_data.items():
        media_dict[key]             = value
    return media_dict


def get_metadata_dict(data: list[dict], existing_media: dict, media_type: str):
    out_dict = dict()
    for item in data:
        db_id               = item['db_id']
        existing_metadata   = existing_media.get(db_id, {})
        label_title         = existing_metadata.get('label_title', item['title'])
        release_year        = existing_metadata.get('release_year', item['release_year'])
        sort_title          = existing_metadata.get('sort_title', get_sort_title(label_title))
        out_dict[db_id]     = get_media_dict(label_title, release_year, sort_title, existing_metadata)
        
        # Special handling for shows to add seasons
        if media_type == 'show':
            for season in item['seasons']:
                season_num = season['number']
                if 'seasons' not in out_dict[db_id]:
                    out_dict[db_id]['seasons'] = dict()
                if season_num not in out_dict[db_id]['seasons']:
                    out_dict[db_id]['seasons'][season_num] = dict()
                if 'url_poster' not in out_dict[db_id]['seasons'][season_num]:
                    out_dict[db_id]['seasons'][season_num]['url_poster'] = ''

    # Retain old movies and shows in case they are added back in future
    for db_id, metadata in existing_media.items():
        if db_id not in out_dict:
            out_dict[db_id] = metadata
    
    return dict(sorted(out_dict.items(), key=lambda item: zero_pad(item[1]['sort_title'].casefold())))


if __name__ == '__main__':
    arg_parser = ArgumentParser('kometa_metadata_file_updater')
    arg_parser.add_argument('--movie_file', type=file_path, help="Path to the movie metadata file")
    arg_parser.add_argument('--show_file', type=file_path, help="Path to the show metadata file")
    arg_parser.add_argument('--json_data', type=json_string, help="JSON data containing movie and show information")

    args                = arg_parser.parse_args()
    existing_movies     = get_existing_metadata(args.movie_file)
    existing_shows      = get_existing_metadata(args.show_file)
    data                = json.loads(args.json_data)
    pp(get_metadata_dict(data['movies'], existing_movies, 'movie'))
    pp(get_metadata_dict(data['shows'], existing_shows, 'show')[396390])
