.. _intro:

Introduction
============

Why another? There's `adminfiles <https://bitbucket.org/carljm/django-adminfiles/src>`_ and `filebrowser <https://github.com/sehmaschine/django-filebrowser>`_ already.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

Why software gets created? Because someone were unhappy with already existing
software.

That was case for me too - I found it hard to make both those to work the way I
want, so I made my own filebrowser.

Why use BFM?
------------

#. You hate Flash, love HTML5, JavaScript and have modern browser.
#. You want simple and fast interface for managing your files online.
#. You couldn't even make another two work. BFM is simple to setup.

Why you would not want to use BFM yet?
--------------------------------------

#. If you want integrate it with TinyMCE or something of the like, you shouldn't think about BFM. **YET**.
#. You want mature project.
#. You need to support IE, which is not even a browser.

Support tables, dependencies
============================

Browser
-------

**Basic features** covers basic actions like file browsing, directory browsing.

**Advanced features** covers uploading, because that part uses most of modern features.

==========================  ==========================  ==========================
Browser                     Basic features (ver.)       Advanced features (ver.)
==========================  ==========================  ==========================
Chrome/Chromium             1                           7 +
Firefox                     ?                           5 +
Opera                       ?                           Not supported \*
IE                          ?                           10 + \*
Safari                      ?                           5.0 +
==========================  ==========================  ==========================

\* Opera and IE 9 and below doesn't support `XHR2 <http://www.w3.org/TR/XMLHttpRequest2/>`_,
which is used to report upload status.

.. _core_dependencies:

Core dependencies
-----------------

BFM was only tested on Python 2.6 and Python 2.7, so it is safe to assume, that dependencies are as follows:

- Python 2.6 or 2.7
- Django 1.3