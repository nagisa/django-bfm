{% load i18n %}

this.imagePreview = function(files){
    xOffset = -10;
    yOffset = 20;
    $(files).hover(function(e){
        this.t = this.title;
        this.title = "";
        var c = (this.t != "") ? "<br/>" + this.t : "";
        var link = this.href
        $("body").append("<p id='preview'><img src='"+ link +"' alt='Image preview' />"+ c +"</p>");
        $("#preview")
            .css("top",(e.pageY - xOffset) + "px")
            .css("left",(e.pageX + yOffset) + "px")
            .show();
    },
    function(){
        this.title = this.t;
        $("#preview").remove();
    });
    $(files).mousemove(function(e){
        $("#preview")
            .css("top",(e.pageY - xOffset) + "px")
            .css("left",(e.pageX + yOffset) + "px");
    });
};

this.image_info = function(parent){
    filename = parent.find('.filename').text()
    $.getJSON('../__image_info/?d='+directory+'&image='+encodeURIComponent(filename), function(data){
        image_resize(data, filename)
    })
};

function rewrite_file_if_exists(filename){
    var exist = false,
    question = '{% trans "File with name '+filename+' already exists. Rewrite?" %}';
    $.ajax({
        url: '../__exists/?f='+encodeURIComponent(filename)+'&d='+encodeURIComponent(directory),
        async: false}).success(function(rsp){exist = rsp == "YES"});
    return exist ? confirm(question) : true;
}

//Totally needs cleanup
this.image_resize = function(data, fname){
    var dialog = $('.image-resize'), form = dialog.find('form');
    var new_name = fname.split('.'), ext = new_name.pop();
    new_name = new_name.join('.')+'_resized.'+ext
    form.find('input[name="new_name"]').val(new_name).keyup(function(){
        if(this.value != form.find('input[name="old_name"]').val()){
            form.find('.warning').hide()
        }else{
            form.find('.warning').show()
        }
    })
    form.find('input[name="old_name"]').val(fname)
    form.find('input[name="ratio"]').val(data.size[0]/data.size[1])
    form.find('input[name="width"]').val(data.size[0]).keyup(function(){
        if(form.find('input[name="lock"]').prop("checked")){
            form.find('input[name="height"]').val(~~(this.value/form.find('input[name="ratio"]').val()))
        }
    })
    form.find('input[name="height"]').val(data.size[1]).keyup(function(){
        if(form.find('input[name="lock"]').prop("checked")){
            form.find('input[name="width"]').val(~~(this.value*form.find('input[name="ratio"]').val()))
        }
    })
    form.find('input[name="ratio"]').val(data.size[0]/data.size[1])
    console.log(data.size[0]/data.size[1])
    form.unbind();
    form.submit(function(){
        if(!rewrite_file_if_exists(form.find('input[name="new_name"]').val())){
            return false;
        }
        form.find('.error').hide();
        $.ajax({'url': '../__resize_image/', 'data': {'image': fname,
                'd': directory,
                'nimage':form.find('input[name="new_name"]').val(),
                'width': form.find('input[name="width"]').val(),
                'height': form.find('input[name="height"]').val(),
                'filter': form.find('select[name="filter"] option:selected').val()},
                'success': function(){dialog.hide()},
                'error': function(){form.find('.error').text('Unexpected error').show()}
                })
        return false;
    })
    dialog.show()
}

function dir_up(){
    var l = window.location, tmp;
    tmp = l.search.split('/');
    tmp.pop();
    l.search = tmp.join('/');
    return false;
}

$(function(){
    $('#select_all').change(function(){
        if(this.checked){
            $('input[name=selected]').each(function(){
                this.checked = true;
            })
        }else{
            $('input[name=selected]').each(function(){
                this.checked = false;
            })
        }
    })
    var files = $('.file td a[href$=".png"]')
    var exts = ['.jpg', '.jpeg', '.gif', '.svg']
    for(key in exts){
        files = $.merge(files, $('.file td a[href$="'+exts[key]+'"]'))
    }
    imagePreview(files);
    $('.resize-button').click(function(){
        image_info($(this).parent().parent().parent())
    })
})
