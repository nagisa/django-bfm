from django.http import HttpResponseForbidden

def staff_required(function):
    """
    If user is not staff, then HTTP 403 will be raised.
    """
    def _staff_required(*args, **kwargs):
        if args[0].user.is_staff:
            return function(*args, **kwargs)
        else:
            return HttpResponseForbidden()
    return _staff_required