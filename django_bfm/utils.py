import os
import settings
from django.core.files.storage import FileSystemStorage


class Directory(object):

    def __init__(self, rel_dir):
        self.rel_dir = (rel_dir+"/").lstrip('/')
        directory = os.path.join(settings.MEDIA_DIRECTORY, self.rel_dir)
        self.s = FileSystemStorage(directory)

    def collect_dirs(self):
        def childs(path):
            return [{'name': name, 'childs': childs(os.path.join(path, name))}
                    for name in os.listdir(path)
                    if os.path.isdir(os.path.join(path, name))]
        return childs(self.s.path(''))