from django.utils import simplejson
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseServerError, HttpResponseNotFound, HttpResponse, HttpResponseBadRequest
from utils import get_dir

def _failed(handler, reason):
    return handler(simplejson.dumps({'status': 'failed', 'reason': reason}))

def open_image(GET):
    from PIL import Image
    directory = get_dir(GET)[0]
    image_name = GET.get('image', False)
    if not image_name:
        raise ValueError, 'No image specified'
    return Image.open(directory.storage.path(image_name)), directory, Image

@login_required
@staff_member_required
def image_info(request):
    try:
        image = open_image(request.GET)[0]
    except ImportError:
        return _failed(HttpResponseServerError, 'Please install PIL')
    except ValueError:
        return _failed(HttpResponseNotFound, 'No image specified')
    except IOError:
        return _failed(HttpResponseNotFound, 'Image with such name not found')

    return HttpResponse(simplejson.dumps({'status': 'success',
                                           'info': image.info,
                                           'size': image.size,
                                           'format': image.format,
                                           'mode': image.mode}))

@login_required
@staff_member_required
def image_resize(request):
    try:
        image, directory, Image = open_image(request.GET)
    except ImportError:
        return _failed(HttpResponseServerError, 'Please install PIL')
    except ValueError:
        return _failed(HttpResponseNotFound, 'No image specified')
    except IOError:
        return _failed(HttpResponseNotFound, 'Image with such name not found')

    width = int(request.GET.get('width', False))
    height = int(request.GET.get('height', False))
    new_image = request.GET.get('nimage', request.GET['image'])
    filt = request.GET.get('filter', 'ANTIALIAS')
    ratio = float(image.size[0])/float(image.size[1])
    if not width and not height:
        return _failed(HttpResponseBadRequest, 'At least height or width must be specified.')
    elif not width:
        width = int(height*ratio)
    elif not height:
        height = int(width/ratio)
    filters = {'ANTIALIAS': Image.ANTIALIAS, 'BICUBIC': Image.BICUBIC,
               'BILINEAR': Image.BILINEAR, 'NEAREST': Image.NEAREST}
    try:
        filt = filters[filt]
    except IndexError:
        return _failed(HttpResponseBadRequest, 'Such filter does not exist')
    image = image.resize((width, height), filt)
    try:
        image.save(directory.storage.path(new_image))
    except:
        return _failed(HttpResponseServerError, 'Couldn\'t save image')
    return HttpResponse('{\'status\': \'OK\'}')
