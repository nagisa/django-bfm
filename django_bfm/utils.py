import os
import settings
from django.core.files.storage import FileSystemStorage
from mimetypes import guess_type as guess_mimetype
from urlparse import urljoin


class Directory(object):

    def __init__(self, rel_dir):
        self.rel_dir = (rel_dir+"/").lstrip('/')
        directory = os.path.join(settings.MEDIA_DIRECTORY, self.rel_dir)
        url = urljoin(settings.MEDIA_URL, self.rel_dir)
        self.s = FileSystemStorage(directory, url)

    def collect_dirs(self):
        def childs(path):
            return [{'name': name,
                    'childs': childs(os.path.join(path, name)),
                    'rel_dir': os.path.relpath(os.path.join(path, name),
                                               self.s.path(''))}
                    for name in os.listdir(path)
                    if os.path.isdir(os.path.join(path, name))]
        return childs(self.s.path(''))

    def collect_files(self):
        files = self.s.listdir('')[1]
        for key, f in enumerate(files):
            files[key] = {'filename': f, 'size': self.s.size(f),
                          'rel_dir': self.rel_dir,
                          'date': self.s.created_time(f).isoformat(),
                          'extension': os.path.splitext(f)[1],
                          'mimetype': guess_mimetype(f)[0] or "unknown",
                          'url': self.s.url(f)}
        return files