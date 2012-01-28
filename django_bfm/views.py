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
def file_actions(request):
    directory = request.GET.get('directory', False)
    filename = request.GET.get('file', False)
    action = request.GET.get('action', False)
    if directory == False or filename == False or not action:
        return HttpResponseBadRequest()

    action = action.lower()
    storage = BFMStorage(directory)

    # Initialize signal args dictionary and send pre_file_action signal.
    if action in ('delete', 'touch', 'rename'):
        sargs = {'sender': request, 'action': action, 'affected_files': {
            'original': storage.path(filename), 'new': None
        }}
        signals.pre_file_action.send(**sargs)

    if action == 'delete':
        storage.delete(filename)
        signals.post_file_action.send(**sargs)
        return HttpResponse()

    elif action == 'touch':
        storage.touch(filename)
        signals.post_file_action.send(**sargs)
        return HttpResponse(storage.file_metadata(filename, json=True))

    elif action == 'rename':
        new_name = request.GET.get('new', False)
        if not new_name:
            return HttpResponseBadRequest()
        new_path = storage.rename(filename, new_name)
        sargs['affected_files']['new'] = new_path
        signals.post_file_action.send(**sargs)
        return HttpResponse(storage.file_metadata(new_name, json=True))

    else:
        return HttpResponseBadRequest()


@login_required
@staff_member_required
def directory_actions(request):
    directory = request.GET.get('directory', False)
    action = request.GET.get('action', False)
    if directory == False or not action:
        return HttpResponseBadRequest()

    action = action.lower()
    storage = BFMStorage(directory)
    root = BFMStorage('')

    # Initialize signal args dictionary and send pre_directory_action signal.
    if action in ('new', 'rename', 'delete'):
        sargs = {'sender': request, 'action': action, 'affected_directories': {
            'original': storage.path(''), 'new': None
        }}
        signals.pre_directory_action.send(**sargs)

    if action == 'new':
        new = request.GET.get('new', False)
        if not new:
            return HttpResponseBadRequest()
        new_directory = storage.new_directory(new, strict=True)
        sargs['affected_directories']['new'] = new_directory
        signals.post_directory_action.send(**sargs)
        return HttpResponse()

    elif action == 'rename':
        new = request.GET.get('new', False)
        if not new:
            return HttpResponseBadRequest()
        new = os.path.normpath(os.path.join(directory, '..', new))
        new_directory = root.move_directory(directory, new, strict=True)
        sargs['affected_directories']['new'] = new_directory
        signals.post_directory_action.send(**sargs)
        return HttpResponse()

    elif action == 'delete':
        root.remove_directory(directory)
        # No new directories appeared due to this action, so no new affected
        # directory. Send signal as is.
        signals.post_directory_action.send(**sargs)
        return HttpResponse()

    else:
        # We have done nothing, so we should at least send an error.
        return HttpResponseBadRequest()


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


@login_required
@staff_member_required
def image_actions(request):
    if not settings.HAS_PIL:
        return HttpResponseServerError('Install PIL!')
    directory = request.GET.get('directory', False)
    filename = request.GET.get('file', False)
    action = request.GET.get('action', False)
    if directory == False or filename == False or not action:
        return HttpResponseBadRequest()

    storage = BFMStorage(directory)
    filepath = storage.path(filename)
    sargs = {'sender': request, 'affected_files': {
        'original': filepath, 'new': None
    }}

    if action == 'info':
        image = Image.open(filepath)
        s = image.size
        return HttpResponse(simplejson.dumps({'height': s[1], 'width': s[0]}))

    elif action == 'resize':
        signals.pre_image_resize.send(**sargs)
        image = Image.open(filepath)
        # `filter` is name of built-in function.
        filtr = getattr(Image, request.GET['filter'])
        size = (int(request.GET['new_w']), int(request.GET['new_h']))
        image = image.resize(size, filtr)
        new_name = storage.get_available_name(filename)
        image.save(storage.path(new_name))
        sargs['affected_files']['new'] = new_name
        signals.post_image_resize.send(**sargs)
        return HttpResponse(storage.file_metadata(new_name, json=True))
