Django Basic File Manager
=========================

Features
--------

- Multifile Uploads (`Open File Dialog <https://github.com/simukis/django-bfm/blob/master/screenshots/Open%20Files.png>`_)
- Live Upload Status report (`Multiple files <https://github.com/simukis/django-bfm/blob/master/screenshots/Upload2.gif>`_, `One file <https://github.com/simukis/django-bfm/blob/master/screenshots/Upload.gif>`_)
- File browsing (`Parent directory <https://github.com/simukis/django-bfm/blob/master/screenshots/Basic%20File%20Manager%20-%20Browse.png>`_, `Child directory <https://github.com/simukis/django-bfm/blob/master/screenshots/Basic%20File%20Manager%20-%20Browse%20Directory.png>`_)
- Directory support
- Image resizing/Thumbnailing
- No external dependencies, lightweight
- Looks like django admin (extends admin template)

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
- ``BFM_COUNT_DIR_CONTENTS`` (default - ``False``) - boolean. Tells BFM, if it should count files in directory and show them as directory size.
- ``LOGIN_URL`` - user will be redirected there if not logged in.

Things to note
--------------

- You must be logged as staff user to use file manager
- If you're not logged in, then you will be redirected to login page at ``settings.LOGIN_URL``
- It's young project

Tested Browsers
---------------

- Chromium 15
- Midori 0.4.0
- Chrome 13
- Firefox 6
