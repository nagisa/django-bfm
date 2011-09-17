from django.shortcuts import render_to_response
from django.core.context_processors import csrf
from django.contrib.auth.decorators import login_required
from django.contrib.admin.views.decorators import staff_member_required

@login_required
@staff_member_required
def base(request):
    c={}
    c.update(csrf(request))
    return render_to_response('django_bfm/base.html', c)