from django.shortcuts import render_to_response
from django.core.context_processors import csrf
from django.contrib.auth.decorators import login_required
from django.contrib.admin.views.decorators import staff_member_required
from django.utils import simplejson
from django.http import HttpResponse

@login_required
@staff_member_required
def base(request):
    c={}
    c.update(csrf(request))
    return render_to_response('django_bfm/base.html', c)

def list_files(request):
    d = [{'filename': 'Ow May Gawd', 'size': '1024', 'extension': '.a', 'date': '122334'},
         {'filename': 'Ow May Gawd2', 'size': '2048', 'extension': '.b', 'date': '134'}]
    return HttpResponse(simplejson.dumps(d))

def list_directories(request):
    d = [{'name': 'main', 'size': '45', 'childs': [{'name': 'sub1', 'size': '18', 'childs': [{'name': 'subsub1', 'size': '10'}]}]}, {'name': 'main2', 'size': '108'}]
    return HttpResponse(simplejson.dumps(d))