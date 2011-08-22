import os
import settings
from django.core.files.storage import FileSystemStorage

#Most important thing :)
media_storage = FileSystemStorage(settings.MEDIA_DIRECTORY)

def _delete_files(files):
    """
    Given list of filenames will delete them
    """
    for file in files:
        path = media_storage.path(file)
        if os.path.isfile(path):
            os.remove(path)

def _touch_files(files):
    """
    Given list of filenames will update its creation_time attribute
    """
    for file in files:
        path = media_storage.path(file)
        os.utime(path, None)

def _human_readable_size(bytes):
    """
    Converts bytes into human readable file size representation
    """
    bytes = int(bytes)
    if bytes/1073741824.0 > 1:
        return '%.2f GB'%(bytes/1073741824.0)
    elif bytes/1048576.0 > 1:
        return '%.1f MB'%(bytes/1048576.0)
    elif bytes/1024.0 > 1:
        return '%d KB'%(bytes/1024)
    else:
        return '%d B'%bytes

def _collect_file_metadata(listing):
    """
    Given list of paths will return list of files with metadata, like size, extension and so on.
    """
    files = []
    for key in listing:
        if os.path.isfile(media_storage.path(key)):
            file = {'name': key, 'path': media_storage.path(key),
                    'size': _human_readable_size(os.path.getsize(media_storage.path(key))),
                    'accessed_time': media_storage.accessed_time(key), 'created_time': media_storage.created_time(key),
                    'extension': os.path.splitext(key)[1]}
            files.append(file)
    return list(reversed(sorted(files, key=lambda file: file['created_time'])))
