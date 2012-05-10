Settings
========

Users can customize their BFM installation by specifying
options in their ``settings.py`` file.

All settings are read from single dictionary ``BFM``.

Example
-------

::

    BFM = {
        'FILES_PER_PAGE': 25,
        'SIMULTANEOUS_UPLOADS': 4
    }

.. _directories-settings:

Directories and URLs
--------------------

If these values are not set, then BFM defaults to values defined in
``MEDIA_ROOT`` and ``MEDIA_URL``.

**BFM['MEDIA_DIRECTORY']**

The absoulute path to the directory, where files accessible by BFM resides.
Please note, that BFM will not be able to access directories, that are parents
to specified one.

Example: ``/home/example.com/media/uploads/``

Defaults to: ``MEDIA_ROOT``

**BFM['MEDIA_URL']**

URL to use when referring to media located in ``BFM_MEDIA_DIRECTORY``.

Example: ``/media/uploads/`` or ``http://media.example.com/uploads/``

.. note::

    It **must** end in slash.

Defaults to: ``MEDIA_URL``

Other BFM options
-----------------

.. _appearance-settings:

**BFM['FILES_PER_PAGE']**

BFM uses Pagination to ensure, that reasonable ammount of files is displayed at once.
You may specify, how much that "reasonable" is for you by giving this variable an integer value.

Example: ``50``

Default: ``20``

.. _uploader-settings:

**BFM['ADMIN_UPLOAD_DIRECTORY']**

Directory path relative to ``BFM_MEDIA_DIRECTORY``.
Tells BFM where to save files uploaded with :ref:`admin-applet`.

Example: ``admin_files/`` and files will be uploaded to ``{{BFM_MEDIA_DIRECTORY}}/admin_files/``.

Default: empty string.

**BFM['UPLOADS_AT_ONCE']**

Tells BFM how much files to upload at once.
Requires integer value.

Example: ``3``

Default: ``2``

.. note::

    If you experiencing issues like dropped connections with uploader then set
    this option to ``1``.

Settings, that aren't directly related to BFM
----------------------------------------------

`LOGIN_URL <https://docs.djangoproject.com/en/dev/ref/settings/#login-url>`_

To make sure, that only authorized users fiddle with files, BFM requires user
to be logged in.
If user is not logged in, it will be redirected to LOGIN_URL.
