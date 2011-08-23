from django.conf import settings

MEDIA_DIRECTORY = getattr(settings,
                          "BFM_MEDIA_DIRECTORY",
                          settings.MEDIA_ROOT)
FILES_IN_PAGE = int(getattr(settings,
                        "BFM_FILES_IN_PAGE",
                        20))
MEDIA_URL = getattr(settings, "BFM_MEDIA_URL", '')
if not MEDIA_URL and MEDIA_DIRECTORY == settings.MEDIA_ROOT:
    MEDIA_URL = settings.MEDIA_URL
COUNT_DIR_CONTENTS = getattr(settings, "BFM_COUNT_DIR_CONTENTS", False)
