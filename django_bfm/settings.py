from django.conf import settings

MEDIA_DIRECTORY = getattr(settings,
                          "BFM_MEDIA_DIRECTORY",
                          settings.MEDIA_ROOT)
FILES_IN_PAGE = getattr(settings,
                        "BFM_FILES_IN_PAGE",
                        20)