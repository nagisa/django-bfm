Settings variables
==================

Variables, that users should define in their ``settings.py`` file, to customize BFM installation.

.. _directories-settings:

Directories and URLs
--------------------

If these values are not set, then BFM takes values from ``MEDIA_ROOT`` and ``MEDIA_URL``.

**BFM_MEDIA_DIRECTORY**

The absoulute path to the directory, where files accessible by BFM resides.
Please note, that BFM will not be able to access directories, that are parents
to specified one.

Example: ``/home/example.com/media/uploads/``

Default: ``MEDIA_ROOT``

**BFM_MEDIA_URL**

URL to use when referring to media located in ``BFM_MEDIA_DIRECTORY``.

Example: ``/media/uploads/`` or ``http://media.example.com/uploads/``

It **must** end in slash.

Default: ``MEDIA_URL`` if empty and ``BFM_MEDIA_DIRECTORY`` is not equal to ``MEDIA_ROOT`` (either by setting by hand or defaulting to that value).

.. _appearance-settings:

BFM appearance
--------------

You can control ammount of files displayed in one page and things like that.

**BFM_FILES_IN_PAGE**

BFM uses Pagination to ensure, that reasonable ammount of files is displayed at once.
You may specify, how much that "reasonable" is for you by giving this variable an integer value.

Example: ``50``

Default: ``20``

**LOGIN_URL**

To make sure, that only authorized users fiddle with, BFM requires user to be logged in.
If user is not logged in, it will be redirected to login.

Please note, that this variable is same as Django `LOGIN_URL <https://docs.djangoproject.com/en/dev/ref/settings/#login-url>`_.

.. _uploader-settings:

Uploader behaviour
------------------

You can control several aspects of uploader like files uploaded at once too.

**BFM_ADMIN_UPLOAD_DIR**

Directory path relative to ``BFM_MEDIA_DIRECTORY``.

Tells BFM where to save files uploaded with :ref:`admin-applet`.

Example: ``admin_files/`` and files will be uploaded to ``/home/example.com/media/uploads/admin_files/``.

Default: empty string.

**BFM_UPLOADS_AT_ONCE**

Tells BFM how much files to upload at once.
Requires integer value.

Example: ``3``

Default: ``2``