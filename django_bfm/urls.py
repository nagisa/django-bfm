from django.conf.urls.defaults import patterns, include, url
from django.conf import settings
if settings.DEBUG:
    from django.contrib.staticfiles.urls import staticfiles_urlpatterns

urlpatterns = patterns('',
    url(r'^$', 'django_bfm.views.base'),
    url(r'^list_files/$', 'django_bfm.views.list_files'),
    url(r'^list_directories/$', 'django_bfm.views.list_directories'),
    url(r'^file/$', 'django_bfm.views.file_actions'),
    url(r'^upfile/$', 'django_bfm.views.file_upload'),
    url(r'^image/$', 'django_bfm.views.image_actions'),
)
if settings.DEBUG:
    urlpatterns += staticfiles_urlpatterns()