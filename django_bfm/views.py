from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest, HttpResponseNotAllowed, HttpResponseRedirect, Http404
from django.core.context_processors import csrf
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger

import settings
from forms import UploadFileForm
from decorators import  staff_required
from utils import _touch_files, _collect_file_metadata, _delete_files, media_storage

def redirect(request):
    #Relative path
    return HttpResponseRedirect('browse/')

@login_required
@staff_required
def browse(request):
    c={}
    c.update(csrf(request))
    content = media_storage.listdir('')
    files = _collect_file_metadata(content[1])
    pages = Paginator(files, settings.FILES_IN_PAGE)
    try:
        page = pages.page(request.GET.get('p', 1))
    except EmptyPage:
        raise Http404
    except PageNotAnInteger:
        raise Http404
    c['files'] = page
    return render_to_response('django_bfm/browse.html', c)

@login_required
@staff_required
def upload(request):
    c = {}
    c.update(csrf(request))
    form = UploadFileForm()
    c['form'] = form
    return render_to_response('django_bfm/upload.html', c)

def _check_file(request):
    """
    Check if file already exists on the server.
    """
    try:
        fname = request.GET['f']
    except KeyError:
        return HttpResponseBadRequest()
    if media_storage.exists(fname):
        return HttpResponse('YES')
    else:
        return HttpResponse('NO')

@login_required
@staff_required
def _upload_file(request):
    """
    Responsible for saving file
    """
    if not request.method == 'POST':
        return HttpResponseNotAllowed(['POST'])
    else:
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            destination = open(media_storage.path(request.FILES['file'].name), 'wb+')
            for chunk in request.FILES['file'].chunks():
                destination.write(chunk)
            destination.close()
        return HttpResponse('Nom Nom...')

@login_required
@staff_required
def select(request):
    """
    Responsible for file deleting and touching
    """
    if not request.method == 'POST':
        return HttpResponseNotAllowed(['POST'])
    else:
        action = request.POST.get('action', False)
        files = dict(request.POST).get('selected', False)
        if not files:
            return HttpResponseRedirect('..')
        if 'delete' in action.lower():
            _delete_files(files)
        elif 'touch' in action.lower():
            _touch_files(files)
        return HttpResponseRedirect('..')