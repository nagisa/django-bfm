from django.conf import settings
from django.utils import simplejson

MEDIA_DIRECTORY = getattr(settings,
                          "BFM_MEDIA_DIRECTORY",
                          settings.MEDIA_ROOT)

MEDIA_URL = getattr(settings, "BFM_MEDIA_URL", '')
if not MEDIA_URL and MEDIA_DIRECTORY == settings.MEDIA_ROOT:
    MEDIA_URL = settings.MEDIA_URL

FILES_IN_PAGE = int(getattr(settings,
                        "BFM_FILES_IN_PAGE",
                        20))

UPLOADS_AT_ONCE = int(getattr(settings, "BFM_UPLOADS_AT_ONCE", 2))

ADMIN_UPDIR = getattr(settings, "BFM_ADMIN_UPLOAD_DIR", '')

#PIL installed? Optional dependency.
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

JSON = simplejson.dumps({'files_in_page': FILES_IN_PAGE,
                        'pil': HAS_PIL,
                        'uploads_at_once': UPLOADS_AT_ONCE})
