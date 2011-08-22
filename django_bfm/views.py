from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest, HttpResponseNotAllowed, HttpResponseRedirect, Http404
from django.core.context_processors import csrf
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.contrib.admin.views.decorators import staff_member_required

import settings
from forms import UploadFileForm
from utils import get_dir, Directory

def redirect(request):
    #Relative path
    return HttpResponseRedirect('browse/')

@login_required
@staff_member_required
def browse(request):
    c={}
    c.update(csrf(request))
    directory, rel_dir = get_dir(request.GET)
    files = directory.list_files()
    directories = directory.list_directories()
    pages = Paginator(files, settings.FILES_IN_PAGE)
    try:
        page = pages.page(request.GET.get('p', 1))
    except EmptyPage:
        raise Http404
    except PageNotAnInteger:
        raise Http404
    c['dirs'] = directories
    c['current_dir'] = rel_dir
    c['files'] = page
    return render_to_response('django_bfm/browse.html', c)

@login_required
@staff_member_required
def upload(request):
    c = {}
    c.update(csrf(request))
    form = UploadFileForm()
    rel_dir = get_dir(request.GET)[1]
    c['form'] = form
    c['current_dir'] = rel_dir
    return render_to_response('django_bfm/upload.html', c)

def _check_file(request):
    """
    Check if file already exists on the server.
    """
    try:
        fname = request.GET['f']
    except KeyError:
        return HttpResponseBadRequest()
    directory = get_dir(request.GET)[0]
    if directory.exists(fname):
        return HttpResponse('YES')
    else:
        return HttpResponse('NO')

@login_required
@staff_member_required
def _upload_file(request):
    """
    Responsible for saving file
    """
    if not request.method == 'POST':
        return HttpResponseNotAllowed(['POST'])
    else:
        directory = get_dir(request.GET)[0]
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            destination = directory.storage.path(request.FILES['file'].name)
            destination = open(destination, 'wb+')
            for chunk in request.FILES['file'].chunks():
                destination.write(chunk)
            destination.close()
        return HttpResponse('File received')

@login_required
@staff_member_required
def select(request):
    """
    Responsible for file deleting and touching
    """
    if not request.method == 'POST':
        return HttpResponseNotAllowed(['POST'])
    else:
        directory, rel_dir = get_dir(request.GET)
        action = request.POST.get('action', False)
        files = dict(request.POST).get('selected', False)
        if not files:
            return HttpResponseRedirect('..')
        if 'delete' in action.lower():
            directory.delete_files(files)
        elif 'touch' in action.lower():
            directory.touch_files(files)
        return HttpResponseRedirect('../?d=%s' % rel_dir)
