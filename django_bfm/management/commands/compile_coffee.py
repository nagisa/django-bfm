from optparse import make_option
from datetime import datetime
import os
import subprocess
import sys

from django.core.management.base import BaseCommand, CommandError


def command_exists(which):
    """
    Check that command is executable by subprocess.call
    """
    try:
        p = subprocess.Popen(which, stdout=subprocess.PIPE)
        p.kill()
        return True
    except OSError:
        return False


def compile_coffee(files, result_file, directory):
    print "Compiling {0}...\r".format(result_file),
    sys.stdout.flush()
    cmd = ['coffee',
        '-o', os.path.join(directory, '..'),
        '-j', result_file,
        '-c'] + files
    subprocess.call(cmd)
    now = datetime.now()
    print "[{1}] Compiled {0}!".format(result_file,
                                                    now.strftime('%H:%M:%S'))


class Command(BaseCommand):
    help = 'Compiles django_bfm .coffee files into javascript files.'
    option_list = BaseCommand.option_list + (
        make_option('--watch',
            action='store_true',
            dest='watch',
            default=False,
            help='Watch for changes and recompile when they occur.'),
    )

    def handle(self, *args, **options):
        # Check for requirements. If option --watch is passed, check that we
        # can access pyinotify module.
        if options['watch']:
            try:
                import pyinotify
            except ImportError:
                raise CommandError('To watch for changes you need pyinotify'
                                    ' module installed.')
        if not command_exists('coffee'):
            raise CommandError('To compile .coffee files, you need node.js'
                                ' and coffeescript module for it.')

        # Make absolute path of source files directory and check for it's
        # existence.
        d = os.path.dirname(os.path.abspath(__file__))
        d = os.path.join(d, '..', '..', 'static', 'django_bfm', 'src')
        d = os.path.normpath(d)
        if not os.path.exists(d):
            message = "Couldn't find source directory at {0}"
            raise CommandError(message.format(d))

        # Make absolute paths of all files.
        # It's required step as inotify returns absolute pathes too.
        app_files = [os.path.join(d, x) for x in [
            'browser.coffee', 'directories.coffee',
            'uploader.coffee', 'utils.coffee', 'application.coffee'
        ]]
        admin_files = [os.path.join(d, x) for x in [
            'utils.coffee', 'uploader.coffee', 'admin.coffee'
        ]]
        uploader_files = [os.path.join(d, x) for x in ['upload.jquery.coffee']]

        # Compile files even when watching and start monitoring then.
        compile_coffee(app_files, 'application.js', d)
        compile_coffee(admin_files, 'admin.js', d)
        compile_coffee(uploader_files, 'upload.jquery.js', d)

        # Start watching for changes.
        if options['watch']:
            class ModifyHandler(pyinotify.ProcessEvent):
                def process_IN_MODIFY(self, event):
                    if event.pathname in app_files:
                        compile_coffee(app_files, 'application.js', d)
                    if event.pathname in admin_files:
                        compile_coffee(admin_files, 'admin.js', d)
                    if event.pathname in uploader_files:
                        compile_coffee(uploader_files, 'upload.jquery.js', d)
            manager = pyinotify.WatchManager()
            handler = ModifyHandler()
            notifier = pyinotify.Notifier(manager, default_proc_fun=handler)
            flags = pyinotify.IN_MODIFY
            manager.add_watch(d, flags, rec=True, auto_add=True)
            print('Started watching for changes...'
                    ' Ctrl+C to abort.')
            notifier.loop()
