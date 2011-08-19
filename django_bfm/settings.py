from django.conf import settings

#Have to think of better way?
try:
    MEDIA_DIRECTORY = settings.BFM_MEDIA_DIRECTORY
except:
    MEDIA_DIRECTORY = settings.MEDIA_ROOT

try:
    FILES_IN_PAGE = settings.BFM_FILES_IN_PAGE
except:
    FILES_IN_PAGE = 25