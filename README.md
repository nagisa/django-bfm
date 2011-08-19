Django Basic File Manager
=========================

Simple Django File Manager

Features
--------

* Multifile Uploads ([Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Open%20Files.png))
* Live Upload Status report ([Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Upload.gif))
* File listing and deleting ([Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Basic%20File%20Manager%20-%20Browse.png))
* No external dependencies

Requirements
------------

django_bfm uses HTML5 techniques, so modern browser is required, see Supported Browsers section.

Usage/Install
-------------

No easy_install or pip support yet, so:

* Download package, extract it, and copy django_bfm into your project directory
* Add [`'django_bfm',`] to [`INSTALLED_APPS`] in settings.py.
* Add [`url(r'^files/', include('django_bfm.urls')),`] to [`urlpatterns`] in urls.py
* Access file manager at /files/browse/ 

Supported Browsers(Tested with)
-------------------------------

* Chromium 15
