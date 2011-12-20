from django.shortcuts import render_to_response
from django.contrib.auth.decorators import login_required
from django.contrib.admin.views.decorators import staff_member_required
from django.utils import simplejson
from django.http import (HttpResponse, HttpResponseNotAllowed,
                        HttpResponseBadRequest, HttpResponseServerError)
from django.template import RequestContext
from django.core.urlresolvers import reverse

import utils
import os
from forms import UploadFileForm
import settings

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
        "upload": reverse("bfm_upload")
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
    storage = utils.Directory(directory)
    files = storage.collect_files()
    return HttpResponse(simplejson.dumps(files))


@login_required
@staff_member_required
def list_directories(request):
    storage = utils.Directory('')
    d = storage.collect_dirs()
    return HttpResponse(simplejson.dumps(d))


@login_required
@staff_member_required
def file_actions(request):
    directory = request.GET.get('directory', False)
    f = request.GET.get('file', False)
    action = request.GET.get('action', False)
    if directory == False or f == False or not action:
        return HttpResponseBadRequest()

    storage = utils.Directory(directory)
    if action == 'delete':
        storage.s.delete(f)
        return HttpResponse()

    elif action == 'touch':
        os.utime(storage.s.path(f), None)
        return HttpResponse(simplejson.dumps(storage.file_metadata(f)))

    elif action == 'rename':
        new_name = request.GET.get('new', False)
        if not new_name:
            return HttpResponseBadRequest()
        else:
            os.rename(storage.s.path(f), storage.s.path(new_name))
        return HttpResponse(simplejson.dumps(storage.file_metadata(new_name)))


@login_required
@staff_member_required
def file_upload(request):
    if not request.method == 'POST':
        return HttpResponseNotAllowed(['POST'])

    directory = request.GET.get('directory', False)
    if directory == False:
        return HttpResponseBadRequest()
    # Parsing form
    form = UploadFileForm(request.POST, request.FILES)
    storage = utils.Directory(directory)
    if form.is_valid():
        f = storage.s.save(request.FILES['file'].name, request.FILES['file'])
        return HttpResponse(simplejson.dumps(storage.file_metadata(f)))
    else:
        return HttpResponseBadRequest()


@login_required
@staff_member_required
def image_actions(request):
    if not 'Image' in globals():
        return HttpResponseServerError('Install PIL!')
    directory = request.GET.get('directory', False)
    f = request.GET.get('file', False)
    action = request.GET.get('action', False)
    if directory == False or f == False or not action:
        return HttpResponseBadRequest()
    storage = utils.Directory(directory)
    fpath = storage.s.path(f)

    if action == 'info':
        image = Image.open(fpath)
        s = image.size
        return HttpResponse(simplejson.dumps({'height': s[1], 'width': s[0]}))

    if action == 'resize':
        image = Image.open(fpath)
        filtr = getattr(Image, request.GET['filter'])
        size = (int(request.GET['new_w']), int(request.GET['new_h']))
        image = image.resize(size, filtr)
        new_name = storage.s.get_available_name(f)
        image.save(storage.s.path(new_name))
    return HttpResponse(simplejson.dumps(storage.file_metadata(new_name)))
