# Python imports
import os

# Django imports
from django.core.urlresolvers import reverse
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.http import (HttpResponse, HttpResponseNotAllowed,
                        HttpResponseBadRequest, HttpResponseServerError)
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.utils import simplejson
from django.utils.decorators import method_decorator
from django.views.generic import View

# Project imports
from forms import UploadFileForm
import signals
import settings
from storage import BFMStorage

#Optional dependecy for image_actions
try:
    from PIL import Image
except:
    pass


@login_required
@staff_member_required
def base(request):
    c = RequestContext(request, {
        'settings': settings.JSON,
        'root': reverse("bfm_base")
    })
    return render_to_response('django_bfm/base.html', c)


def admin_options(request):
    admin_options = {
        "upload": reverse("bfm_upload"),
        "upload_rel_dir": settings.ADMIN_UPDIR
    }
    c = RequestContext(request, {
        'settings': settings.JSON,
        'admin_options': simplejson.dumps(admin_options)
    })
    return render_to_response('django_bfm/admin.js', c)


def client_templates(request):
    c = RequestContext(request, {})
    return render_to_response('django_bfm/client_side/base.html', c)


@login_required
@staff_member_required
def list_files(request):
    directory = request.GET.get('directory', '')
    files = BFMStorage(directory).list_files(json=True)
    return HttpResponse(files)


@login_required
@staff_member_required
def list_directories(request):
    directory_tree = BFMStorage('').directory_tree()
    return HttpResponse(simplejson.dumps(directory_tree))


@login_required
@staff_member_required
def file_upload(request):
    directory = request.GET.get('directory', False)
    if request.method != 'POST':
        return HttpResponseNotAllowed(['POST'])
    elif directory == False:
        return HttpResponseBadRequest()

    form = UploadFileForm(request.POST, request.FILES)
    storage = BFMStorage(directory)

    if form.is_valid():
        signals.pre_uploaded_file_save.send(sender=request)
        f = storage.save(request.FILES['file'].name, request.FILES['file'])
        signals.uploaded_file_saved.send(sender=request,
                                        file_path=storage.path(f))
        return HttpResponse(storage.file_metadata(f, json=True))

    else:
        return HttpResponseBadRequest('Form is invalid!')


class FileActions(View):

    @method_decorator(login_required)
    @method_decorator(staff_member_required)
    def dispatch(self, request):
        # Check for all required arguments and move them to another dict.
        self.args = {'directory': None, 'action': None, 'file': None}
        for arg in self.args:
            if arg not in request.GET:
                return HttpResponseBadRequest()
            self.args[arg] = request.GET[arg]
        # Rename needs `new` variable.
        self.args['new'] = request.GET.get('new', False)

        # Initialize storage.
        self.storage = BFMStorage(self.args['directory'])

        # Initialize signals
        self.signals = {'pre': signals.pre_file_action,
                        'post': signals.post_file_action}
        self.sigfile = {'original': self.storage.path(self.args['file']),
                        'new': None}
        self.sigargs = {'sender': request,
                        'action': self.args['action'],
                        'affected_files': self.sigfile}

        # Send signals and run action, then send post signal.
        a = {'delete': self.delete, 'rename': self.rename, 'touch': self.touch}
        if self.args['action'] in a:
            self.signals['pre'].send(**self.sigargs)
            response = a[self.args['action']]()
            if not response.status_code >= 400:
                self.signals['post'].send(**self.sigargs)
            return response
        else:
            return HttpResponseBadRequest()

    def delete(self):
        self.storage.delete(self.args['file'])
        return HttpResponse()

    def touch(self):
        self.storage.touch(self.args['file'])
        new_meta = self.storage.file_metadata(self.args['file'], json=True)
        return HttpResponse(new_meta)

    def rename(self):
        if self.args['new'] is False:
            return HttpResponseBadRequest()
        new_path = self.storage.rename(self.args['file'], self.args['new'])
        self.sigfile['new'] = new_path
        new_meta = self.storage.file_metadata(self.args['new'], json=True)
        return HttpResponse(new_meta)


class DirectoryActions(View):

    @method_decorator(login_required)
    @method_decorator(staff_member_required)
    def dispatch(self, request):
        self.args = {'directory': None, 'action': None}
        for arg in self.args:
            if arg not in request.GET:
                return HttpResponseBadRequest()
            self.args[arg] = request.GET[arg]
        # Rename and New needs `new` variable.
        self.args['new'] = request.GET.get('new', False)

        # Initialize storage.
        self.storage = BFMStorage(self.args['directory'])
        self.root = BFMStorage('')

        # Initialize signals
        self.signals = {'pre': signals.pre_directory_action,
                        'post': signals.post_directory_action}
        self.sigfile = {'original': self.storage.path(''),
                        'new': None}
        self.sigargs = {'sender': request,
                        'action': self.args['action'],
                        'affected_files': self.sigfile}

        # Send signals and run action, then send post signal.
        a = {'new': self.new, 'rename': self.rename, 'delete': self.delete}
        if self.args['action'] in a:
            self.signals['pre'].send(**self.sigargs)
            response = a[self.args['action']]()
            if not response.status_code >= 400:
                self.signals['post'].send(**self.sigargs)
            return response
        else:
            return HttpResponseBadRequest()

    def new(self):
        if self.args['new'] is False:
            return HttpResponseBadRequest()
        new_dir = self.storage.new_directory(self.args['new'], strict=True)
        self.sigfile['new'] = new_dir
        return HttpResponse()

    def rename(self):
        if self.args['new'] is False:
            return HttpResponseBadRequest()
        path = os.path.join(self.args['directory'], '..', self.args['new'])
        new_dir = self.root.move_directory(self.args['directory'],
                                            os.path.normpath(path), strict=True)
        self.sigfile['new'] = new_dir
        return HttpResponse()

    def delete(self):
        self.root.remove_directory(self.args['directory'])
        return HttpResponse()


class ImageActions(View):

    @method_decorator(login_required)
    @method_decorator(staff_member_required)
    def dispatch(self, request):
        if not settings.HAS_PIL:
            return HttpResponseServerError('Install PIL!')

        self.args = {'directory': None, 'action': None, 'file': None}
        for arg in self.args:
            if arg not in request.GET:
                return HttpResponseBadRequest()
            self.args[arg] = request.GET[arg]

        # Resize action has many more arguments.
        if self.args['action'] == 'resize':
            self.resize_args = {'filter': None, 'new_w': None, 'new_h': None}
            for arg in self.resize_args:
                if arg not in request.GET:
                    return HttpResponseBadRequest()
                self.resize_args[arg] = request.GET[arg]

        # Initialize storage and get image path.
        self.storage = BFMStorage(self.args['directory'])
        self.image = self.storage.path(self.args['file'])

        # Initialize signals.
        self.signals = {'pre': signals.pre_image_resize,
                        'post': signals.post_image_resize}
        self.sigfile = {'original': self.image,
                        'new': None}
        self.sigargs = {'sender': request,
                        'action': self.args['action'],
                        'affected_files': self.sigfile}

        # Send signals and run action.
        a = {'info': self.info, 'resize': self.resize}
        if self.args['action'] in a:
            self.signals['pre'].send(**self.sigargs)
            response = a[self.args['action']]()
            if not response >= 400:
                self.signals['post'].send(**self.sigargs)
            return response
        else:
            return HttpResponseBadRequest()

    def info(self):
        img = Image.open(self.image)
        s = img.size
        sizes = {'height': s[1], 'width': s[0]}
        return HttpResponse(simplejson.dumps(sizes))

    def resize(self):
        _filter = getattr(Image, self.resize_args['filter'])
        size = (int(self.resize_args['new_w']), int(self.resize_args['new_h']))
        img = Image.open(self.image)
        new_image = img.resize(size, _filter)
        new_name = self.storage.get_available_name(self.args['file'])
        new_image.save(self.storage.path(new_name))
        self.sigfile['new'] = self.storage.path(new_name)
        return HttpResponse(self.storage.file_metadata(new_name, json=True))
