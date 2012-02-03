import tempfile
import os
import shutil
from collections import defaultdict

from django.core.urlresolvers import reverse
from django.utils import simplejson
from django.conf import settings

from django_bfm.tests.utils import ClientTestCase
from django_bfm import signals

# Patching environment.
temp_directory = tempfile.mkdtemp()
settings.BFM_MEDIA_DIRECTORY = temp_directory
settings.BFM_MEDIA_URL = 'http://testserver/'


class FileUpload(ClientTestCase):

    def setUp(self):
        super(FileUpload, self).setUp()
        # Signals...
        self.got_pre = defaultdict(int)
        self.got_post = defaultdict(int)
        signals.pre_uploaded_file_save.connect(self.pre)
        signals.uploaded_file_saved.connect(self.post)
        # Uploadable
        self.upl_content = 'Hello, World!'
        self.uploadable = tempfile.mkstemp()[1]
        with open(self.uploadable, 'w') as f:
            f.write(self.upl_content)

    def pre(self, signal, sender):
        self.got_pre['upload'] += 1

    def post(self, signal, sender, file_path):
        # Uploaded file path should be absolute and existing.
        self.assertTrue(os.path.exists(file_path))
        self.assertTrue(os.path.isfile(file_path))
        self.got_post['upload'] += 1

    def test_not_authorized(self):
        r = self.client.post(reverse('bfm_upload'), {'doesnt_matter': 'what'})
        # We should be redirected to login...
        self.assertEqual(r.status_code, 302)

    def test_authorized_upload(self):
        self.login_super()

        # Sending request without file should fail.
        r = self.client.post(reverse('bfm_upload'), {})
        self.assertEqual(r.status_code, 400)

        # Upload file.
        with open(self.uploadable, 'r') as f:
            r = self.client.post("{}?directory=".format(reverse('bfm_upload')),
                                                                {'file': f})
        # Test: 1) Response JSON correctness; 2) Correct file saving;
        self.assertEqual(r.status_code, 200)
        parsed = simplejson.loads(r.content)
        file_path = os.path.join(temp_directory, parsed['filename'])
        self.assertEqual(open(file_path).read(), self.upl_content)
        self.assertEqual(self.got_pre['upload'], 1)
        self.assertEqual(self.got_post['upload'], 1)

    # @unittest.skip("Strange Django behavior.") # only 2.7...
    def test_unauthorized(self):
        # Strange. when logging in as non-super user, @staff_member_required
        # says that session has expired instead of throwing error...
        return  # Skip it
        self.login()
        r = self.client.post(reverse('bfm_upload'), {})
        print r.content

    def tearDown(self):
        signals.pre_uploaded_file_save.disconnect(self.pre)
        signals.uploaded_file_saved.disconnect(self.post)
        if os.path.exists(self.uploadable):
            os.remove(self.uploadable)


class DirectoryActions(ClientTestCase):

    def setUp(self):
        super(DirectoryActions, self).setUp()
        # Create dummy directory.
        # Needed for testing rename and/or delete.
        self.new_dir = os.path.join(temp_directory, "dir_actions")
        os.mkdir(self.new_dir)

        self.dir_url = "{}directory/".format(reverse('bfm_base'))
        self.got_pre = defaultdict(int)
        self.got_post = defaultdict(int)
        signals.pre_directory_action.connect(self.pre)
        signals.post_directory_action.connect(self.post)

    def pre(self, signal, sender, action, affected_files):
        self.got_pre[action] += 1

    def post(self, signal, sender, action, affected_files):

        self.got_post[action] += 1

    def test_unauthorized(self):
        r = self.client.get(self.dir_url, {})
        # We should be redirected to login.
        self.assertEqual(r.status_code, 302)

    def test_arguments(self):
        self.login_super()
        # Giving no arguments should fail.
        r = self.client.get(self.dir_url, {})
        self.assertEqual(r.status_code, 400)
        r = self.client.get(self.dir_url, {'directory': ''})
        self.assertEqual(r.status_code, 400)
        args = {'directory': '', 'action': 'new'}
        r = self.client.get(self.dir_url, args)
        self.assertEqual(r.status_code, 400)
        # We shouldn't test got_pre here, because it may or may not be sent
        # even if error occurs.
        self.assertEqual(self.got_post['new'], 0)

    def test_create_new(self):
        self.login_super()

        args = {'directory': '', 'action': 'new', 'new': 'hello_world'}
        r = self.client.get(self.dir_url, args)
        self.assertEqual(r.status_code, 200)
        exists = os.path.exists(os.path.join(temp_directory, 'hello_world'))
        self.assertTrue(exists)
        self.assertEqual(self.got_pre['new'], 1)
        self.assertEqual(self.got_post['new'], 1)

    def test_delete(self):
        self.login_super()

        # Let's delete our poor dummy directory.
        args = {'directory': 'dir_actions', 'action': 'delete'}
        r = self.client.get(self.dir_url, args)
        self.assertEqual(r.status_code, 200)
        exists = os.path.exists(os.path.join(temp_directory, 'dir_actions'))
        self.assertFalse(exists)
        self.assertEqual(self.got_pre['delete'], 1)
        self.assertEqual(self.got_post['delete'], 1)

    def test_rename(self):
        self.login_super()

        args = {'directory': 'dir_actions', 'action': 'rename', 'new': 'moved'}
        r = self.client.get(self.dir_url, args)
        self.assertEqual(r.status_code, 200)
        exists = os.path.exists(os.path.join(temp_directory, 'dir_actions'))
        exists2 = os.path.exists(os.path.join(temp_directory, 'moved'))
        self.assertTrue(exists2)
        self.assertFalse(exists)
        args = {'directory': 'moved', 'action': 'rename', 'new': 'lets/fail'}
        with self.assertRaises(OSError):
            r = self.client.get(self.dir_url, args)
        exists2 = os.path.exists(os.path.join(temp_directory, 'moved'))
        self.assertTrue(exists2)
        # Even tough second rename promises to raise error, it must send
        # pre_action signal before actually doing action and failing.
        self.assertEqual(self.got_pre['rename'], 2)
        self.assertEqual(self.got_post['rename'], 1)

    def tearDown(self):
        # Remove dummy directory.
        if os.path.exists(self.new_dir):
            shutil.rmtree(self.new_dir)

        # Disconnect signals...
        signals.pre_directory_action.disconnect(self.pre)
        signals.post_directory_action.disconnect(self.post)


class FileActions(ClientTestCase):

    def setUp(self):
        super(FileActions, self).setUp()

        # Create dummy file.
        # Needed for testing rename and/or delete.
        self.new_file = os.path.join(temp_directory, "file_actions")
        self.file_content = 'Hello, World!'
        with open(self.new_file, 'w') as f:
            f.write(self.file_content)
        self.file_url = "{}file/".format(reverse('bfm_base'))

        # Signals
        self.got_pre = defaultdict(int)
        self.got_post = defaultdict(int)
        signals.pre_file_action.connect(self.pre)
        signals.post_file_action.connect(self.post)

    def pre(self, signal, sender, action, affected_files):
        self.got_pre[action] += 1

    def post(self, signal, sender, action, affected_files):
        self.got_post[action] += 1

    def test_unauthorized(self):
        r = self.client.get(self.file_url, {})
        self.assertEqual(r.status_code, 302)  # Redirect to login page.

    def test_arguments(self):
        self.login_super()
        # No action should fail.
        args = {'directory': '', 'file': 'file_actions', 'action': ''}
        r = self.client.get(self.file_url, args)
        self.assertEqual(r.status_code, 400)
        # No arguments should fail.
        r = self.client.get(self.file_url, {})
        self.assertEqual(r.status_code, 400)

    def test_touch_and_times(self):
        self.login_super()

        old_stats = os.stat(self.new_file)
        os.utime(self.new_file, (0, 0))

        args = {'directory': '', 'file': 'file_actions', 'action': 'touch'}
        r = self.client.get(self.file_url, args)
        self.assertEqual(r.status_code, 200)
        stats = os.stat(self.new_file)
        self.assertAlmostEqual(stats.st_atime, old_stats.st_atime, delta=1)
        self.assertAlmostEqual(stats.st_mtime, old_stats.st_mtime, delta=1)

        loaded = simplejson.loads(r.content)
        self.assertAlmostEqual(stats.st_mtime * 1000, loaded['date'],
                                                                    delta=1000)
        self.assertEqual(self.got_pre['touch'], 1)
        self.assertEqual(self.got_post['touch'], 1)

    def test_rename(self):
        self.login_super()

        args = {'directory': '', 'file': 'file_actions', 'action': 'rename'}
        r = self.client.get(self.file_url, args)
        self.assertEqual(r.status_code, 400)

        args['new'] = 'file_actions2'
        r = self.client.get(self.file_url, args)
        self.assertEqual(r.status_code, 200)
        new_path = os.path.join(temp_directory, 'file_actions2')
        self.assertTrue(os.path.exists(new_path))
        self.assertFalse(os.path.exists(self.new_file))

        # Renaming (moving) to another directory should fail...
        args['file'] = 'file_actions2'
        args['new'] = 'file/file_actions'
        with self.assertRaises(OSError):
            r = self.client.get(self.file_url, args)

        self.assertEqual(self.got_pre['rename'], 3)
        self.assertEqual(self.got_post['rename'], 1)

    def test_delete(self):
        self.login_super()

        args = {'directory': '', 'file': 'file_actions', 'action': 'delete'}
        r = self.client.get(self.file_url, args)
        self.assertEqual(r.status_code, 200)
        self.assertFalse(os.path.exists(self.new_file))

    def tearDown(self):
        if os.path.exists(self.new_file):
            os.remove(self.new_file)
        signals.pre_file_action.disconnect(self.pre)
        signals.post_file_action.disconnect(self.post)
