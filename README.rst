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

Additional Features (uses dependencies and/or are optional)
--------------------------------------------------------

- Image resizing (PIL)
- Admin upload applet

Requirements
------------

- Modern browser - BFM relies on a bunch of HTML5 features.
- Django 1.3 (Not tested with 1.2 and below)

Usage/Install
-------------

Istallation instructions can be found here: `Installation Instructions <https://github.com/simukis/django-bfm/wiki/Installation>`_

Settings
--------

Variables in settings.py, that influence behavior of BFM are in `Wiki <https://github.com/simukis/django-bfm/wiki/Settings>`_

Things to note
--------------

- You must be logged as staff user to use file manager
- If you're not logged in, then you will be redirected to login page at ``settings.LOGIN_URL``
- It's young project

Tested Browsers
---------------

You can check browser support at `Browser support wiki page <https://github.com/simukis/django-bfm/wiki/Browser-support>`_