upload_stats = {};

function parse_size(size){
    //~~ is double bitwise NOT. It rounds. Very quickly.
    if(size/1073741824 > 1){
        return (size/1073741824 + 0.5).toFixed(2) + " GB"
    }else if(size / 1048576 > 1){
        return (size / 1048576 + 0.5).toFixed(1) + " MB"
    }else if(size / 1024 > 1){
        return ~~(size / 1024 + 0.5) + " KB"
    }else{
        return size + " B"
    }
}

function parse_transfer_rate(transfered, time){
    var t = ~~((transfered*1000/time)+0.5);
    return parse_size(t)+'/s'
}

function rewrite_file_if_exists(filename){
    var exist = false,
    question = 'File with name '+filename+' already exists. Rewrite?';
    $.ajax({
        url: '../__exists/?f='+encodeURIComponent(filename)+'&d='+encodeURIComponent(dir),
        async: false}).success(function(rsp){exist = rsp == "YES"});
    return exist ? confirm(question) : true;
}

function create_queue(filer){
    var files = filer.files,
        table = $('#filelist'),
        file,
        row = 1,
        tr, filename, size;
    for(file=0; file<files.length; file++){
        filename = files[file].name;
        if(!rewrite_file_if_exists(filename)){
            continue;
        }
        size = parse_size(files[file].size);
        tr = $('<tr/>', {'id': 'file' + file,
                         'class': "row" + row}).appendTo(table);
        $('<td/>', {'text': filename}).appendTo(tr);
        $('<td/>', {'text': size}).appendTo(tr);
        $('<td/>', {'class': 'speed'}).appendTo(tr);
        $('<td/>', {'class': 'progress'}).appendTo(tr);
        row = (row % 2) + 1;
    }
    $('#step1').hide();
    $('#step2').show();
}

function start_upload(){
    $('#step2').hide();
    $('#step3').show();
    queue = $.makeArray($('tr[id^=file]'));
    upload_next_file();
}

function get_file_id(element){
    return element.id.match(/\d+/)[0];
}

function upload_progress(evt){
    var speed = $(current).find('.speed'),
    progress = $(current).find('.progress'),
    s = upload_stats,
    time_difference = new Date() - s.ltime,
    size_difference = evt.loaded - s.lload;
    if(time_difference > 3000){
        //Some averagization
        upload_stats.ltime = new Date();
        upload_stats.lload = evt.loaded
    }
    progress.text((evt.loaded * 100 / s.size).toFixed(1)+" %")
    speed.text(parse_transfer_rate(size_difference, time_difference))
}

function upload_complete(evt){
    var speed = $(current).find('.speed'),
    progress = $(current).find('.progress'),
    time_difference = new Date() - upload_stats.start;

    progress.text('100%');
    speed.text(parse_transfer_rate(upload_stats.size,
                                   time_difference))
    upload_next_file();
}

function upload_fail(){
    var speed = $(current).find('.speed'),
    progress = $(current).find('.progress');
    speed.text('0 B/s');
    progress.text('FAILED');
    $(current).css('background-color', '#F5A9A9')
    upload_next_file();
}

function upload_cancel(){
    var speed = $(current).find('.speed'),
    progress = $(current).find('.progress');
    speed.text('0 B/s');
    progress.text('CANCELED');
    $(current).css('background-color', '#F7D358')
    upload_next_file();
}

function all_uploads_complete(){
    $('#uploading').text('Completed').click(function(){
        window.location.reload()
    })
    $('#cancel').hide()
    return true;
}

function upload_next_file(){
    current = queue.shift();
    if(!current){
        //We're done with our work.
        return all_uploads_complete();
    }
    var id = get_file_id(current),
    file = document.getElementById('fileselection').files[id],
    xhr = new XMLHttpRequest(),
    fd = new FormData(),
    csrf_token = $('input[name=csrfmiddlewaretoken]').val(),
    s = upload_stats = {'start': new Date(), 'size': file.size,
                        'ltime': new Date(), 'lload': 0,
                        'xhr': xhr};


    fd.append("file", file);
    xhr.upload.addEventListener("progress", upload_progress, false);
    xhr.addEventListener("load", upload_complete, false);
    xhr.addEventListener("error", upload_fail, false);
    xhr.addEventListener("abort", upload_cancel, false);
    xhr.open("POST", "file/?d="+dir);
    xhr.setRequestHeader("X-CSRFToken", csrf_token);
    xhr.send(fd);
}
