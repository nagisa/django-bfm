from django.conf.urls.defaults import patterns, url
from django_bfm import views

urlpatterns = patterns('',
    url(r'^$', views.base, name="bfm_base"),
    url(r'^list_files/$', views.list_files),
    url(r'^list_directories/$', views.list_directories),
    url(r'^action/$', views.FileActions.as_view()),
    url(r'^directory/$', views.DirectoryActions.as_view()),
    url(r'^upfile/$', views.file_upload, name="bfm_upload"),
    # url(r'^image/$', views.ImageActions.as_view()),
    # Utilities
    url(r'^admin_options/$', views.admin_options, name="bfm_opt"),
    url(r'^client_templates/$', views.client_templates, name='bfm_templates')
)
