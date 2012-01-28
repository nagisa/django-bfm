# Python imports
import os

# Django imports
from django.shortcuts import render_to_response
from django.contrib.auth.decorators import login_required
from django.contrib.admin.views.decorators import staff_member_required
from django.utils import simplejson
from django.http import (HttpResponse, HttpResponseNotAllowed,
                        HttpResponseBadRequest, HttpResponseServerError)
from django.template import RequestContext
from django.core.urlresolvers import reverse

# Project imports
from forms import UploadFileForm
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
    if action == 'delete':
        storage.delete(filename)
        return HttpResponse()
    elif action == 'touch':
        storage.touch(filename)
        return HttpResponse(storage.file_metadata(filename, json=True))
    elif action == 'rename':
        new_name = request.GET.get('new', False)
        if not new_name:
            return HttpResponseBadRequest()
        storage.rename(filename, new_name)
        return HttpResponse(storage.file_metadata(new_name, json=True))
    else:
        return HttpResponseBadRequest()  # Nothing to do!


@login_required
@staff_member_required
def directory_actions(request):
    directory = request.GET.get('directory', False)
    action = request.GET.get('action', False)
    if directory == False or not action:
        return HttpResponseBadRequest()

    storage = BFMStorage(directory)
    root = BFMStorage('')
    if action == 'new':
        new = request.GET.get('new', False)
        if not new:
            return HttpResponseBadRequest()
        storage.new_directory(new)
        return HttpResponse()
    elif action == 'rename':
        new = request.GET.get('new', False)
        if not new:
            return HttpResponseBadRequest()
        new = os.path.normpath(os.path.join(directory, '..', new))
        root.move_directory(directory, new)
        return HttpResponse()
    elif action == 'delete':
        root.remove_directory(directory)
        return HttpResponse()
    else:
        return HttpResponseBadRequest()  # Nothing to do!


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
        f = storage.save(request.FILES['file'].name, request.FILES['file'])
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
    if action == 'info':
        image = Image.open(filepath)
        s = image.size
        return HttpResponse(simplejson.dumps({'height': s[1], 'width': s[0]}))
    elif action == 'resize':
        image = Image.open(filepath)
        filtr = getattr(Image, request.GET['filter'])
        size = (int(request.GET['new_w']), int(request.GET['new_h']))
        image = image.resize(size, filtr)
        new_name = storage.get_available_name(filename)
        image.save(storage.path(new_name))
        return HttpResponse(storage.file_metadata(new_name, json=True))
