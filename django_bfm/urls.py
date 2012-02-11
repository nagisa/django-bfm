from django.conf.urls.defaults import patterns, url
from django_bfm import views

urlpatterns = patterns('',
    url(r'^$', 'django_bfm.views.base', name="bfm_base"),
    url(r'^list_files/$', 'django_bfm.views.list_files'),
    url(r'^list_directories/$', 'django_bfm.views.list_directories'),
    url(r'^file/$', views.FileActions.as_view()),
    url(r'^directory/$', views.DirectoryActions.as_view()),
    url(r'^upfile/$', 'django_bfm.views.file_upload', name="bfm_upload"),
    url(r'^image/$', views.ImageActions.as_view()),
    url(r'^admin_options/$', 'django_bfm.views.admin_options', name="bfm_opt"),
    url(r'^client_templates/$', views.client_templates, name='bfm_templates')
)
