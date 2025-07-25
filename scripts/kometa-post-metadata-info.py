# THIS IS THE CLIENT SIDE SCRIPT

import os
import re
import requests
import json
from pprint import pp

movie_dir = '/media/plex/movies' # Replace with the path to your movies root dir
show_dir = '/media/plex/shows' # Replace with the path to your shows root dir
kometa_configs_repository = 'ChaseRoohms/kometa-configs' # Replace with your repository
token = 'REPLACE_ME_WITH_GH_FGPAT'
post_data = {
    'movies': list(),
    'shows': list()
}

def repository_dispatch(data: dict):
    response = requests.post(
        url=f'https://api.github.com/repos/{kometa_configs_repository}/dispatches',
        headers={
            'Authorization': f'Bearer {token}',
            'Accept': 'Accept: application/vnd.github.v3+json',
        },
        data=json.dumps({
            "event_type": "metadata_file_update",
            "client_payload": {"data": data}
            })
    )
    if response.status_code != 204:
        raise Exception(f'Something went wrong posting the data to GitHub\n\t\t{response.text}')

def folder_iterator(root_dir):
    for file in os.listdir(root_dir):
        if os.path.isdir(f'{root_dir}/{file}'):
            yield file

def get_media_info(folder: str, match: re.Match[str]) -> tuple[str, str, str]:
    db_id_str       = match.group(0)
    db_id_str       = db_id_str.replace('{tmdb-', '')
    db_id_str       = db_id_str.replace('{tvdb-', '')
    db_id_str       = db_id_str.replace('}', '')
    db_id           = int(db_id_str)
    year_match      = re.search(r'\([0-9]{4}\)', folder)
    year            = year_match.group(0) if year_match is not None else '(Unknown)'
    release_year    = year.replace('(', '').replace(')', '')
    title           = folder.replace(match.group(0), '').replace(year, '').strip()
    title           = title.replace('(', '').replace(')', '').replace('\'', '')
    return db_id, title, release_year

for folder_name in folder_iterator(movie_dir):
    db_match = re.search(r'{t[vm]db-[0-9]+}', folder_name)
    if db_match:
        db_id, title, release_year = get_media_info(folder_name, db_match)
        post_data['movies'].append({
            'title': title,
            'release_year': release_year,
            'db_id': db_id
        })

for folder_name in folder_iterator(show_dir):
    db_match = re.search(r'{t[vm]db-[0-9]+}', folder_name)
    if db_match:
        db_id, title, release_year = get_media_info(folder_name, db_match)
        show_dict = {
            'title': title,
            'release_year': release_year,
            'db_id': db_id,
            'seasons': list()
        }
        for inner_folder in folder_iterator(f'{show_dir}/{folder_name}'):
            season_num = -1
            if inner_folder.lower().startswith('season '):
                season_num = int(inner_folder.lower().replace('season ', ''))
            elif inner_folder.lower() == 'specials':
                season_num = 0
            if season_num != -1:
                if 'seasons' not in show_dict:
                    show_dict['seasons'] = list()
                show_dict['seasons'].append({"number": season_num})
        post_data['shows'].append(show_dict)
repository_dispatch(post_data)
