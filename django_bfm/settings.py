from django.conf import settings
from django.utils import simplejson

BFM = {
    # Defaults
    'MEDIA_DIRECTORY': settings.MEDIA_ROOT,
    'MEDIA_URL': settings.MEDIA_URL,
    'FILES_PER_PAGE': 20,
    'SIMULTANEOUS_UPLOADS': 2,
    'ADMIN_UPLOAD_DIRECTORY': '',

}

if hasattr(settings, 'BFM'):
    BFM.update(settings.BFM)

JSON = simplejson.dumps({
    'simultaneous_uploads': BFM['SIMULTANEOUS_UPLOADS'],
    'files_per_page': BFM['FILES_PER_PAGE']
})
