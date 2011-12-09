"""
Compiles all coffee's into one big .js when any of those .coffee's changes.
Used for develovepment.
"""

import subprocess
import os.path
import pyinotify


directory = os.path.dirname(os.path.abspath(__file__))
app_files = [os.path.abspath(x) for x in [
    'browser.coffee',
    'directories.coffee',
    'uploader.coffee',
    'utils.coffee',
    'application.coffee'
]]

admin_files = [os.path.abspath(x) for x in [
    'utils.coffee',
    'uploader.coffee',
    'admin.coffee'
]]

uploader_files = [os.path.abspath(x) for x in [
    'upload.jquery.coffee'
]]


class ModifyHandler(pyinotify.ProcessEvent):
    extensions = ['.coffee']

    def compile_app(self):
        cmd = ['coffee',
            '-o', os.path.join(directory, '..'),  # Result path
            '-j', 'application.js',  # Result name
            '-c'] + app_files  # Files to combine and compile
        subprocess.call(cmd)
        print "==> Compiled Application coffee!"

    def compile_admin(self):
        cmd = ['coffee',
            '-o', os.path.join(directory, '..'),
            '-j', 'admin.js',
            '-c'] + admin_files
        subprocess.call(cmd)
        print "==> Compiled Admin coffee!"

    def compile_uploader(self):
        cmd = ['coffee',
            '-o', os.path.join(directory, '..'),
            '-j', 'upload.jquery.js',
            '-c'] + uploader_files
        subprocess.call(cmd)
        print "==> Compiled jQuery Uploader coffee!"

    def process_IN_MODIFY(self, event):
        if not any(event.pathname.endswith(ext) for ext in self.extensions):
            return
        if event.pathname in app_files:
            self.compile_app()
        if event.pathname in admin_files:
            self.compile_admin()
        if event.pathname in uploader_files:
            self.compile_uploader()
        else:
            return

manager = pyinotify.WatchManager()
handler = ModifyHandler()
notifier = pyinotify.Notifier(manager, default_proc_fun=handler)
flags = pyinotify.IN_MODIFY
manager.add_watch(directory, flags, rec=True, auto_add=True)
print '==> Started monitoring %s for changes!' % directory
handler.compile_app()
handler.compile_admin()
handler.compile_uploader()
notifier.loop()
