import yaml
import os

from argparse import ArgumentParser, ArgumentTypeError


def file_path(path_str):
    if os.path.isfile(path_str):
        return path_str
    else:
        raise ArgumentTypeError(f'File not found: {path_str}')


def get_existing_metadata(filename: str) -> dict:
    '''
    Retrieves the metadata saved in "filename"
    '''
    if not filename.endswith('.yml') and not filename.endswith('.yaml'):
        raise Exception('Function "get_existing_metadata" requires filename to be a yaml file ending in ".yml" or ".yaml"')
    with open(filename, 'r') as metadata_file:
        return yaml.safe_load(metadata_file)['metadata']


def get_tpdb_search_link(title: str, section: str):
    search_link = 'https://theposterdb.com/search'
    search_term = f'?term={title.replace(' ', '+')}'
    search_section = f'&section={section}'
    return search_link + search_term + search_section


def get_missing_movie_poster_dict(db_id: int, metadata: dict) -> dict:
    return {
        'db_id': db_id,
        'title': metadata['label_title'],
        'release_year': metadata.get('release_year', 'Unknown'),
        'tpdb_search': get_tpdb_search_link(metadata['label_title'], 'movies')
    }


def get_missing_show_poster_dict(db_id: int, metadata: dict, seasons: list) -> dict:
    return {
        'db_id': db_id,
        'title': metadata['label_title'],
        'release_year': metadata.get('release_year', 'Unknown'),
        'seasons': ', '.join(seasons),
        'tpdb_search': get_tpdb_search_link(metadata['label_title'], 'shows')
    }


def get_missing_movie_posters(metadata_dict: dict) -> dict:
    poster_issues = list()
    for db_id, metadata in metadata_dict.items():
        url_poster = metadata.get('url_poster')
        if url_poster is None or url_poster == '':
            poster_issues.append(get_missing_movie_poster_dict(db_id, metadata))
    return poster_issues


def get_missing_show_posters(metadata_dict: dict) -> dict:
    poster_issues = list()
    for db_id, metadata in metadata_dict.items():
        seasons = list()
        url_poster = metadata.get('url_poster')
        if url_poster is None or url_poster == '':
            seasons.append('Parent')
        for season, season_metadata in metadata.get('seasons').items():
            if season_metadata is not None:
                season_poster = season_metadata.get('url_poster')
                if season_poster is None or season_poster == '':
                    seasons.append(str(season))
        if len(seasons) > 0:
            poster_issues.append(get_missing_show_poster_dict(db_id, metadata, seasons))
    return poster_issues


def write_movie_report(missing_posters, filepath):
    with open(filepath, 'w') as report_file:
        report_file.write('## Movies missing a url_poster\n\n')
        if len(missing_posters) == 0:
            report_file.write('All movies have a poster linked, check back later!')
        else:
            header  = '|TMDB ID|Title|Release Year|Find a Poster|\n'
            divider = '|-------|-----|------------|-------------|\n'
            report_file.write(header)
            report_file.write(divider)
            for item in missing_posters:
                db_id = f'[{item['db_id']}](https://www.themoviedb.org/movie/{item['db_id']})'
                title = item['title']
                year = item['release_year']
                search = f'[Search on TPDB]({item['tpdb_search']})'
                line = f'|{db_id}|{title}|{year}|{search}|'
                report_file.write(f'{line}\n')


def write_show_report(missing_posters, filepath):
    with open(filepath, 'w') as report_file:
        report_file.write('## Shows missing a url_poster\n\n')
        if len(missing_posters) == 0:
            report_file.write('All movies have a poster linked, check back later!')
        else:
            header  = '|TMDB ID|Title|Release Year|Missing Seasons|Find a Poster|\n'
            divider = '|-------|-----|------------|---------------|-------------|\n'
            report_file.write(header)
            report_file.write(divider)
            for item in missing_posters:
                db_id = f'[{item['db_id']}](https://www.thetvdb.com/search?query={item['db_id']})'
                title = item['title']
                year = item['release_year']
                seasons = item['seasons']
                search = f'[Search on TPDB]({item['tpdb_search']})'
                line = f'|{db_id}|{title}|{year}|{seasons}|{search}|'
                report_file.write(f'{line}\n')


if __name__ == '__main__':
    arg_parser = ArgumentParser('kometa_missing_poster_finder')
    arg_parser.add_argument('--movie_file', type=file_path, help="Path to the movie metadata file")
    arg_parser.add_argument('--show_file', type=file_path, help="Path to the show metadata file")

    args                = arg_parser.parse_args()
    existing_movies     = get_existing_metadata(args.movie_file)
    existing_shows      = get_existing_metadata(args.show_file)

    write_movie_report(get_missing_movie_posters(existing_movies), 'poster_report_movies.md')
    write_show_report(get_missing_show_posters(existing_shows), 'poster_report_shows.md')
