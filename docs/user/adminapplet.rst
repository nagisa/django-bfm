.. _admin-applet:

Admin Applet
============

Making admin applet to work requires more work because application specific files should be edited.

Firstly open your application, in which you want applet to appear, ``admin.py`` file.

Add these just after imports

::

    from django.core.urlresolvers import reverse
    from django.utils.functional import lazy
    reverse_lazy = lazy(reverse, str)

Then in your ``SomethingAdmin`` class add another `class named Media <https://docs.djangoproject.com/en/dev/ref/contrib/admin/#modeladmin-media-definitions>`_, if it doesn't exist yet.

After that add ``reverse_lazy('bfm_opt')`` into ``js`` tuple.

In the end Media class should look something like this:

::

    class EntryAdmin(admin.ModelAdmin):
        class Media:
            # ... Your other css and js ...
            js += (reverse_lazy('bfm_opt'),)
        #Your admin continues here...

That's all. You're ready to see your applet in http://example.com/admin/application/model.

You may want to change some options, that changes behavior of Admin applet. You can see them in :ref:`uploader-settings`.

Notes
-----

BFM javascript file downloads all files it requires including newest version of jQuery, so all ``$`` and ``jQuery`` variables defined before will be rewritten. ``django.jQuery`` variable will be left in it's place.