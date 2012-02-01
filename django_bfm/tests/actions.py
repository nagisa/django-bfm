import tempfile
import os

from django.core.urlresolvers import reverse
from django.utils import simplejson
from django.conf import settings

from django_bfm.tests.utils import AuthTestCase
from django_bfm import signals

temp_directory = tempfile.mkdtemp()
settings.BFM_MEDIA_DIRECTORY = temp_directory
settings.BFM_MEDIA_URL = 'http://testserver/'


class FileUpload(AuthTestCase):

    def setUp(self):
        super(FileUpload, self).setUp()

    def test_not_authorized(self):
        r = self.client.post(reverse('bfm_upload'), {'doesnt_matter': 'what'})
        # We should be redirected to login...
        self.assertEqual(r.status_code, 302)

    def test_authorized_upload(self):
        self.login_super()

        # Sending request without file should fail.
        r = self.client.post(reverse('bfm_upload'), {})
        self.assertEqual(r.status_code, 400)

        # Test upload and uploaded file contents.
        path = tempfile.mkstemp()
        with open(path[1], 'w') as f:
            f.write('Hello, World!')
        with open(path[1], 'r') as f:
            r = self.client.post("{}?directory=".format(reverse('bfm_upload')), {'file': f})
            self.assertEqual(r.status_code, 200)
            parsed = simplejson.loads(r.content)
            file_path = os.path.join(temp_directory, parsed['filename'])
            self.assertEqual(open(file_path).read(), 'Hello, World!')

        #Clean up.
        os.remove(path[1])
        os.remove(file_path)
        self.client.logout()

    def test_unauthorized(self):
        """
        Strange. when logging in as non-super user, @staff_member_required
        says that session has expired instead of throwing error...
        """
    #   self.login()
    #   r = self.client.post(reverse('bfm_upload'), {})
    #   print r.content
    #   self.client.logout()

    def test_signals(self):
        self.pre = False
        self.post = False

        def pre_f(signal, sender):
            self.pre = True

        def post_f(signal, sender, file_path):
            # file_path should be absolute path to existing file, which was
            # just uploaded.
            self.assertEqual(open(file_path).read(), "Hello, World!")
            self.post = True

        signals.pre_uploaded_file_save.connect(pre_f)
        signals.uploaded_file_saved.connect(post_f)

        self.test_authorized_upload()
        self.assertTrue(self.pre)
        self.assertTrue(self.post)

        signals.pre_uploaded_file_save.disconnect(pre_f)
        signals.uploaded_file_saved.disconnect(post_f)
        del(self.pre)
        del(self.post)
