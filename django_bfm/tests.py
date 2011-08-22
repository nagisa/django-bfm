from django.test import TestCase
from utils import Directory, _human_readable_size, get_dir
import settings
import os
from django.test.client import Client


class DirectoryTest(TestCase):
    def setUp(self):
        self.d = Directory('')

    def test_current_directory(self):
        """
        Tests that Directory('') always opens settings.MEDIA_DIRECTORY.
        get_dir should do same.
        """
        self.assertEqual(self.d.storage.path(''), settings.MEDIA_DIRECTORY)
        get = {'d': ''}
        di = get_dir(get)
        self.assertEqual(di[1], '')
        self.assertEqual(di[0].storage.path(''), settings.MEDIA_DIRECTORY)

    def test_replace_dir_up(self):
        get = {'d': '/folder/../a/b/'}
        di = get_dir(get)
        self.assertEqual(di[1],'a/b')
        self.assertEqual(di[0].storage.path(''), os.path.normpath(os.path.join(settings.MEDIA_DIRECTORY, 'folder/../a/b/')))

    def test_size_conversion(self):
        hrs = _human_readable_size
        self.assertEqual(hrs(1024), '1 KB')
        self.assertEqual(hrs(1024*1024), '1.0 MB')
        self.assertEqual(hrs(1024*1024*1024), '1.00 GB')
        self.assertEqual(hrs(1024*1024*1024 + 1), '1.00 GB')
        self.assertEqual(hrs(1024*1024*1024 + 1024*1024*10), '1.01 GB')
