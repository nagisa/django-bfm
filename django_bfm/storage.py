# Python imports
from mimetypes import guess_type as guess_mimetype
import os
import shutil
from urlparse import urljoin

# Django imports
from django.core.files.storage import FileSystemStorage
from django.utils import simplejson
from django.utils._os import safe_join

# Project imports
import settings
from utils import json_handler


class BFMStorage(FileSystemStorage):

    def __init__(self, rel_dir=None):
        if rel_dir is None or rel_dir == '/' or rel_dir == "":
            self.rel_dir = ''
        else:
            self.rel_dir = '{}/'.format(rel_dir.strip('/'))
        directory = safe_join(settings.MEDIA_DIRECTORY, self.rel_dir)
        url = urljoin(settings.MEDIA_URL, self.rel_dir)
        super(BFMStorage, self).__init__(directory, url)

    def file_metadata(self, filename, json=False):
        default_mime = "application/octet-stream"
        metadata = {
            'filename': filename,
            'size': self.size(filename),
            'rel_dir': self.rel_dir,
            'date': self.created_time(filename),
            'mimetype': guess_mimetype(filename)[0] or default_mime,
            'url': self.url(filename)
            # 'ext': os.path.splitext(filename)[1]
        }
        if json:
            return simplejson.dumps(metadata, default=json_handler)
        else:
            return metadata

    def list_files(self, json=False):
        files = self.listdir('')[1]
        for key, f in enumerate(files):
            files[key] = self.file_metadata(f)
        if json:
            return simplejson.dumps(files, default=json_handler)
        else:
            return files

    def directory_tree(self, json=False):
        directories = {}
        base = self.path('')
        for root, dirs, _ in os.walk(base):
            for dir_name in dirs:
                rel_dir = os.path.relpath(safe_join(root, dir_name), base)
                directories[rel_dir] = {
                    'name': dir_name,
                    'rel_dir': rel_dir,
                    'children': []
                }
                if root != base:
                    parent_dir = os.path.dirname(rel_dir)
                    directories[parent_dir]['children'].append(rel_dir)
        if json:
            return simplejson.dumps(directories.values(), default=json_handler)
        else:
            return directories.values()

    def touch(self, filename):
        os.utime(self.path(filename), None)

    def rename(self, filename, to):
        to = self.path(self.get_available_name(to))
        os.rename(self.path(filename), to)
        return to

    def new_directory(self, path, recursive=False, strict=False):
        if self.get_available_name(path) != path and strict:
            message = "File or directory with name {} already exists!"
            raise IOError(message.format(path))
        path = self.path(self.get_available_name(path))
        if recursive:
            os.makedirs(path)
        else:
            os.mkdir(path)
        return path

    def move_directory(self, path, to, strict=False):
        if self.get_available_name(to) != to and strict:
            message = "File or directory with name {} already exists!"
            raise IOError(message.format(path))
        path = self.path(path)
        to = self.path(self.get_available_name(to))
        os.rename(path, to)
        return to

    def remove_directory(self, path):
        shutil.rmtree(self.path(path))
