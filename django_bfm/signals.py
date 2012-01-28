from django.dispatch import Signal

# Signal sent after uploaded file is saved into filesystem.
# sender variable is Request object.
# file_path argument is absolute path to saved file.
uploaded_file_saved = Signal(providing_args=['file_path'])
# And one which is called just before saving file.
pre_uploaded_file_save = Signal()

# Signals sent before and after user initiated actions on files are executed.
# sender = Request object
# action = which action was or is to be executed
# affected_files = which files will be affected. It will contain dictionary
# with all affected files.
pre_file_action = Signal(providing_args=['action', 'affected_files'])
post_file_action = Signal(providing_args=['action', 'affected_files'])

# Signals sent before and after user initiated actions on files are executed.
# Arguments are same as pre/post_file_action, except that affected_files is
# named affected_directories.
pre_directory_action = Signal(providing_args=['action',
                                                'affected_directories'])
post_directory_action = Signal(providing_args=['action',
                                                'affected_directories'])

# Signals sent before and after user initiated image resize is executed.
# Arguments are same as pre/post_file_action
pre_image_resize = Signal(providing_args=['affected_files'])
post_image_resize = Signal(providing_args=['affected_files'])


# Affected files dictionary:
# Most oftenly it will contain two keys: original and new
# `original` key will contain path to file, upon which action was executed
# `new` key will contain path to file which was created due to action
# After action is executed, `original` file is not guaranteed to be existing.
# As well `new` key can be None, which would indicate that no new files were
# created.
# Note that `new` key in pre signals will always be empty.
