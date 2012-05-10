.. _intro:

Introduction
============

Why another? There's `adminfiles <https://bitbucket.org/carljm/django-adminfiles/src>`_ and `filebrowser <https://github.com/sehmaschine/django-filebrowser>`_ already.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

Why software is created in the first place?
Because there is somebody who is not satisfied with already existing solutions.
I'm one of those people and I think that I can do better.

Why use BFM?
------------

#. You hate Flash, love HTML5, CSS3, JavaScript and have modern browser.
#. You want simple and fast interface for managing your files online.
#. You couldn't even make another two work. BFM is simple to setup.

Why you would not want to use BFM yet?
--------------------------------------

#. You need to support IE, which is actually not even a browser.
#. You want a mature project.
#. If you want integrate it with TinyMCE or something of the like, you shouldn't think about BFM.

Support tables, dependencies
============================

Browser
-------

Version, required to have full functionality of BFM. Some parts of BFM may still
work with older browsers, but advanced functionality, like file uploading won't.

==========================  ==========================
Browser                     Version
==========================  ==========================
Chrome/Chromium             7 +
Firefox                     5 +
Opera                       12.0 + \*
IE                          10 + \*
Safari                      5.0 +
==========================  ==========================


**\*** `XHR2 <http://www.w3.org/TR/XMLHttpRequest2/>`_,
which is used internally to upload files and report upload status,
is not supported by stable versions of these browsers.

.. _core_dependencies:

Dependencies
------------

BFM was only tested on Python 2.6 and Python 2.7, so it is safe to assume, that dependencies are as follows:

- Python: 2.6 or 2.7,
- Django: 1.3 or 1.4
