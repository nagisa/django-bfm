{% load i18n %}
{% autoescape off %}
window.BFMAdminOptions = {{ admin_options|safe }};
window.BFMOptions = {{ settings|safe }};
(function($){
    var __bind = function(fn, me){
        return function(){ return fn.apply(me, arguments); };
    };

    load_scripts = function(scripts, callback){
        var len = scripts.length,
        loaded = 0;

        clbk = function(){
            loaded += 1;
            if(loaded === len){
                callback();
            }
        }
        for(var i=0; i<len; i++){
            $.ajax({
                async:false,
                type:'GET',
                url:scripts[i],
                success:__bind(function(){clbk()}, this),
                dataType:'script'
            });
        }
    };

    load_scripts([
        'http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js'
    ], function(){
        $("<script id=\"uploader_tpl\" type=\"text/template\">\n    <div class=\"uploader-head\">\n        {% trans 'Uploader' %}\n        <a class=\"control iconic fullscreen\" title=\"{% trans 'Expand uploader' %}\" data-alttitle=\"{% trans 'Minimize uploader' %}\"></a>\n    </div>\n    <div class=\"uploader-controls breadcrumbs\">\n        <form class=\"selector\">\n            <input type=\"file\" multiple>\n            <a class=\"iconic plus\" href=\"#\"> {% trans 'Add files' %}</a>\n        </form>\n        <form class=\"selector directory\">\n            <input type=\"file\"  webkitdirectory directory mozdirectory>\n            <a class=\"iconic plus\" href=\"#\"> {% trans 'Add folder (experimental)' %}</a>\n        </form>\n        <a class=\"iconic trash finished\" href=\"#\"> {% trans 'Clear finished' %}</a>\n        <a class=\"iconic trash rqueued\" href=\"#\"> {% trans 'Remove queued' %}</a>\n    </div>\n    <div class=\"uploader-table-container\">\n        <div class=\"uploader-table\">\n        </div>\n    </div>\n</script>\n\n\n<script id=\"file_upload_tpl\" type=\"text/template\">\n    <div class=\"file\">\n        <div class=\"status\"></div>\n        <a class=\"abort iconic x\" title=\"{% trans 'Cancel this upload' %}\"></a>\n        <%= filename %>\n        <span class=\"indicators\">\n            (<span class=\"percent\">0</span>% @ <span class=\"speed\">0 B/s</span>)\n        </span>\n        <span class=\"failed\">({% trans 'Failed' %})</span>\n        <span class=\"aborted\">({% trans 'Aborted' %})</span>\n    </div>\n</script>").appendTo('head');
        load_scripts([
            'http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.1.7/underscore-min.js',
            'http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.5.3/backbone-min.js',
        ], function(){
            load_scripts([
                '{{ STATIC_URL }}django_bfm/admin.js',
                '{{ STATIC_URL }}django_bfm/upload.jquery.js'
            ], function(){})
        });
    });

    style = $("<link />", {
        type:'text/css',
        rel:'stylesheet',
        href: '{{ STATIC_URL }}django_bfm/application.css'
    }).appendTo($('head'))

})(django.jQuery);
{% endautoescape %}