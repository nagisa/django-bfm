.. _install:

Installation
============

pip and easy_install
--------------------

Easiest way to install BFM is to use ``pip``:

::

    $ pip install django_bfm

And second to easiest is with ``easy_install``:

::

    $ easy_install django_bfm

.. note::

    Using easy_install is discouraged. Why? `Read here <http://www.pip-installer.org/en/latest/other-tools.html#pip-compared-to-easy-install>`_.

GIT repository
--------------

Alternatively, you can clone and install from Github repository, where project is developed.

::

    $ git clone git://github.com/simukis/django-bfm.git
    $ cd django-bfm
    $ python2 setup.py install

or with pip:

::

    pip install -e git+git://github.com/simukis/django-bfm.git#egg=Package

.. note::

    Do not forget to compile .coffee files yourself if you are cloning
    repository from ``master``. You can do so by running
    ``manage.py compile_coffee``.


.. _configure:

Configuration
=============

Enabling BFM
------------

After downloading and installing BFM, you need to configure your Django project.

#. Add ``'django_bfm',`` to your ``INSTALLED_APPS`` in **settings.py**,
#. Add ``url(r'^files/', include('django_bfm.urls')),`` to your ``urlpatterns`` in **urls.py**,
#. Make sure you have `staticfiles enabled <https://docs.djangoproject.com/en/dev/howto/static-files/#basic-usage>`_ (`with a context processor <https://docs.djangoproject.com/en/dev/howto/static-files/#with-a-context-processor>`_) and run `python manage.py collectstatic`,
#. Make sure, that static files are served correctly by your production server.

.. note::

    You don't need to run collectstatic if you are working in develovepment
    server. It serves files automatically.

Next steps
----------

.. toctree::
   :maxdepth: 2

   settingsvars
