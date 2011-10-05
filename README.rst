Django Basic File Manager
=========================

Core Features
-------------

- Multifile Uploads (`Open File Dialog <https://github.com/simukis/django-bfm/blob/master/screenshots/Open%20Files.png>`_)
- Live Upload Status report (`Upload applet <https://github.com/simukis/django-bfm/blob/master/screenshots/Upload.gif>`_)
- File browsing
- Directory support
- Core features has no dependencies (except for Django), lightweight
- Looks like django admin (extends admin template)

Additional Features (uses dependencies and are optional)
--------------------------------------------------------

- Image resizing (PIL)

Requirements
------------

- Modern browser - BFM relies on a bunch of HTML5 features.
- Django 1.3 (Not tested with 1.2 and below)

Usage/Install
-------------

- Install it with either of:
    + ``pip install django_bfm``
    + ``easy_install django_bfm``
    + You can also put django_bfm directory directly into your project directory, if you want.
- Add following to ``INSTALLED_APPS`` in your project settings.py. ::

    'django_bfm',

- Add following to ``urlpatterns`` in urls.py ::

    url(r'^files/', include('django_bfm.urls')),

Settings
--------

Variables in settings.py, that influence behavior of BFM. `Wiki <https://github.com/simukis/django-bfm/wiki/Settings>`_ has more extensive explanation, so you may want to look at it.

- ``BFM_MEDIA_DIRECTORY`` (if not set, then ``MEDIA_ROOT`` is used) - absolute path to directory, where uploaded files are.
- ``BFM_MEDIA_URL`` (may use ``MEDIA_URL`` as value) - Let's BFM to construct clickable links to files.
- ``BFM_FILES_IN_PAGE`` (default - ``20``) - integer. Tells BFM, how much files to show in one page.
- ``LOGIN_URL`` - user will be redirected there if not logged in.

Things to note
--------------

- You must be logged as staff user to use file manager
- If you're not logged in, then you will be redirected to login page at ``settings.LOGIN_URL``
- It's young project

Tested Browsers
---------------

- Chromium 15, 16
- Midori 0.4.0
- Chrome 13
- Firefox 6, 7, 10

Tested and (all or some) features does not work
-----------------------------------------------

- Opera 11.51 and below (Doesn't support new XHR specification, so uploads do not work)