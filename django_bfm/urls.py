from django.conf.urls.defaults import patterns, include, url

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'Dlog.views.home', name='home'),
    url(r'^browse/$', 'django_bfm.views.browse'),
    url(r'^upload/$', 'django_bfm.views.upload'),
    url(r'^__exists/$', 'django_bfm.views._check_file'),
    url(r'^upload/file/$', 'django_bfm.views._upload_file'),
    url(r'^browse/select/$', 'django_bfm.views.select'),
)