from django.conf.urls.defaults import patterns, include, url

urlpatterns = patterns('',
    url(r'^$', 'django_bfm.views.base'),
    url(r'^list_files/$', 'django_bfm.views.list_files'),
    url(r'^list_directories/$', 'django_bfm.views.list_directories'),
    url(r'^file/$', 'django_bfm.views.file_actions'),
    url(r'^upfile/$', 'django_bfm.views.file_upload', name="bfm_upload"),
    url(r'^image/$', 'django_bfm.views.image_actions'),
    url(r'^admin_options/$', 'django_bfm.views.admin_options', name="bfm_opt")
)