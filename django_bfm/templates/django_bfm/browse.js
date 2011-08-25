this.imagePreview = function(files){
    xOffset = -10;
    yOffset = 20;
    $(files).hover(function(e){
        this.t = this.title;
        this.title = "";
        var c = (this.t != "") ? "<br/>" + this.t : "";
        var link = $(this).find('a').attr('href')
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
    var files = $('.file td').has('a[href$=".png"]')
    var exts = ['.jpg', '.jpeg', '.gif', '.svg']
    for(key in exts){
        files = $.merge(files, $('.file td').has('a[href$="'+exts[key]+'"]'))
    }
    imagePreview(files);
})
