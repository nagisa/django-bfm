from django.conf.urls.defaults import patterns, include, url

urlpatterns = patterns('',
    url(r'^$', 'django_bfm.views.base'),
    url(r'^list_files/$', 'django_bfm.views.list_files')
)
