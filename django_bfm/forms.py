from django import forms

class AttachmentForm(forms.Form):
    file = forms.FileField()
    def __init__(self, bound_object=None, *args, **kwargs):
        super(AttachmentForm, self).__init__(*args, **kwargs)
        self.bound_object = bound_object
        self.is_updating = False
        if self.bound_object:
            self.is_updating = True

    def save(self):
        if not self.is_updating:
            self.bound_object = Attachment()
        # Retrieve the UploadedFile object for the attached_file field.
        uploaded_file = self.cleaned_data['attached_file']
        # Clean up the filename before storing it.
        import re
        stored_name = re.sub(r'[^a-zA-Z0-9._]+', '-', uploaded_file.name)
        # Save the file and its metadata.
        self.bound_object.attached_file.save(stored_name, uploaded_file)
        self.bound_object.mimetype = uploaded_file.content_type