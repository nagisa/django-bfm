import os
import settings
from django.core.files.storage import FileSystemStorage
from django.http import Http404

def _human_readable_size(bytes):
    """
    Converts bytes into human readable file size representation
    """
    bytes = int(bytes)
    if bytes/1073741824.0 >= 1:
        return '%.2f GB'%(bytes/1073741824.0)
    elif bytes/1048576.0 >= 1:
        return '%.1f MB'%(bytes/1048576.0)
    elif bytes/1024.0 >= 1:
        return '%d KB'%(bytes/1024)
    else:
        return '%d B'%bytes

def get_dir(GET):
    try:
        rel_dir = os.path.normpath('/'+GET.get('d', ''))
        directory = Directory(rel_dir)
    except:
        raise Http404
    return directory, (rel_dir+'/').lstrip('/')


class Directory():

    def __init__(self, rel_dir):
        self.rel_dir = (rel_dir+"/").lstrip('/')
        directory = os.path.join(settings.MEDIA_DIRECTORY, self.rel_dir)
        self.storage = FileSystemStorage(directory)

    def exists(self, fname):
        return self.storage.exists(fname)

    def list_directories(self):
        dirs = self.storage.listdir('')[0]
        result = []
        for directory in dirs:

            path = self.storage.path(directory)
            directory = {'name': directory,
                         'path': os.path.relpath(path, settings.MEDIA_DIRECTORY)}
            if settings.COUNT_DIR_CONTENTS:
                directory['count'] = self.count_files(os.walk(path))
            result.append(directory)
        return result

    def list_files(self):
        return self.collect_metadata(self.storage.listdir('')[1])

    def delete_files(self, files):
        for file in files:
            path = self.storage.path(file)
            if os.path.isfile(path):
                os.remove(path)

    def touch_files(self, files):
        for file in files:
            path = self.storage.path(file)
            os.utime(path, None)

    def collect_metadata(self, listing):
        files = []
        for key in listing:
            filepath = self.storage.path(key)
            if os.path.isfile(self.storage.path(key)):
                file = {'name': key,
                        'path': filepath,
                        'size': _human_readable_size(os.path.getsize(filepath)),
                        'accessed_time': self.storage.accessed_time(key),
                        'created_time': self.storage.created_time(key),
                        'extension': os.path.splitext(key)[1]}
                if settings.MEDIA_URL:
                    file['url'] = settings.MEDIA_URL + self.rel_dir + key
                files.append(file)
        return list(reversed(sorted(files, key=lambda file: file['created_time'])))

    def count_files(self, walker):
        return len(sum([files for _, _, files in walker], []))
