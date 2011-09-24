from django.shortcuts import render_to_response
from django.core.context_processors import csrf
from django.contrib.auth.decorators import login_required
from django.contrib.admin.views.decorators import staff_member_required
from django.utils import simplejson
from django.http import HttpResponse

import utils
import os
from forms import UploadFileForm

@login_required
@staff_member_required
def base(request):
    c={}
    c.update(csrf(request))
    return render_to_response('django_bfm/base.html', c)

@login_required
@staff_member_required
def list_files(request):
    directory = request.GET.get('directory', '')
    storage = utils.Directory(directory)
    d = storage.collect_files()
    return HttpResponse(simplejson.dumps(d))

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
    if directory == False or f == False:
        return HttpResponse(simplejson.dumps(False))
    storage = utils.Directory(directory)
    if request.GET.get('action', False) == 'delete':
        storage.s.delete(f)
    elif request.GET.get('action', False) == 'touch':
        os.utime(storage.s.path(f), None)
    elif request.GET.get('action', False) == 'rename':
        new_name = request.GET.get('new', False)
        if new_name == False:
            return HttpResponse(simplejson.dumps(False))
        else:
            os.rename(storage.s.path(f), storage.s.path(new_name))
    else:
        return HttpResponse(simplejson.dumps(False))
    return HttpResponse(simplejson.dumps(True))

@login_required
@staff_member_required
def file_upload(request):
    directory = request.GET.get('directory', False)
    if directory == False or not request.method == 'POST':
        return HttpResponse(simplejson.dumps(False))
    else:
        form = UploadFileForm(request.POST, request.FILES)
        storage = utils.Directory(directory)
        if form.is_valid():
            f = storage.s.save(request.FILES['file'].name,request.FILES['file'])
            return HttpResponse(simplejson.dumps(f))
        return HttpResponse(simplejson.dumps(False))