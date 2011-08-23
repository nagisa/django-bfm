Django Basic File Manager
=========================

Features
--------

* Multifile Uploads ([Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Open%20Files.png))
* Live Upload Status report ([Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Upload2.gif), [Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Upload.gif))
* File browsing ([Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Basic%20File%20Manager%20-%20Browse.png), [Screenshot](https://github.com/simukis/django-bfm/raw/master/screenshots/Basic%20File%20Manager%20-%20Browse%20Directory.png))
* Directory support
* No external dependencies, lightweight
* Looks like django admin (extends admin template)

Requirements
------------

django_bfm extensively uses HTML5 techniques, so modern browser is required, see Tested Browsers section.
Tested only with Django 1.3.

Usage/Install
-------------

* `easy_install django_bfm` or `pip install django_bfm` or download package, extract it, and copy django_bfm into your project directory
* Add `'django_bfm',` to `INSTALLED_APPS` in settings.py.
* Add `url(r'^files/', include('django_bfm.urls')),` to `urlpatterns` in urls.py
* Access file manager at /files/browse/

Settings
--------

Variables in settings.py, that influence behavior of BFM.

* `BFM_MEDIA_DIRECTORY`(if not set `MEDIA_ROOT` is used) - absolute path to place, where uploaded files are.
* `BFM_MEDIA_URL`(if `BFM_MEDIA_DIRECTORY` and `BFM_MEDIA_URL` are not set, then `MEDIA_URL` is used for default value) - Let's BFM to construct clickable links to files.
* `BFM_FILES_IN_PAGE`(default - `20`) - integer. Tells BFM, how much files to show in one page.
* `BFM_COUNT_DIR_CONTENTS`(default - False) - boolean. Tells BFM, if it should count files in directory and show them as directory size. Warning: This one may slow down BFM drastically as all files has to be found to count them.
* `MEDIA_ROOT` and `MEDIA_URL` - used as default values if no `BFM_MEDIA_DIRECTORY` or `BFM_MEDIA_URL` found.
* `LOGIN_URL` - user will be redirected there if not logged in.

Things to note
--------------

* You must be logged as staff user to use file manager
* If you're not logged in, then you will be redirected to login page at `settings.LOGIN_URL`
* It's young project

Tested Browsers
-------------------------------

* Chromium 15
* Midori 0.4.0
* Chrome 13
* Firefox 6
