import os
import settings
from django.core.files.storage import FileSystemStorage
from mimetypes import guess_type as guess_mimetype
from urlparse import urljoin


class Directory(object):

    def __init__(self, rel_dir):
        self.rel_dir = (rel_dir + "/").lstrip('/')
        directory = os.path.join(settings.MEDIA_DIRECTORY, self.rel_dir)
        url = urljoin(settings.MEDIA_URL, self.rel_dir)
        self.s = FileSystemStorage(directory, url)

    def collect_dirs(self):
        directories = {}
        base = self.s.path('')
        for root, dirs, _ in os.walk(base):
            for dir_name in dirs:
                rel_dir = os.path.relpath(os.path.join(root, dir_name), base)
                directories[rel_dir] = {
                    'name': dir_name,
                    'rel_dir': rel_dir,
                    'children': []
                }
                if root != base:
                    parent_dir = os.path.dirname(rel_dir)
                    directories[parent_dir]['children'].append(rel_dir)
        return directories.values()

    def collect_files(self):
        files = self.s.listdir('')[1]
        for key, f in enumerate(files):
            ###
            files[key] = self.file_metadata(f)
        return files

    def file_metadata(self, f):
        return {'filename': f,
                'size': self.s.size(f),
                'rel_dir': self.rel_dir,
                'date': self.s.created_time(f).ctime(),
                'extension': os.path.splitext(f)[1],
                'mimetype': guess_mimetype(f)[0] or "application/octet-stream",
                'url': self.s.url(f)}
