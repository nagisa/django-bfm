(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  django.jQuery(function() {
    var $, file_template, readable_size, select_template, uploadable, uploaded_template, uploader, uploader_template, uploadlist;
    $ = django.jQuery;
    readable_size = function(size) {
      var s, table, _i, _len;
      table = [['B', 1024, 0], ['KB', 1048576, 0], ['MB', 1073741824, 1], ['GB', 1099511627776, 2], ['TB', 1125899906842624, 3]];
      for (_i = 0, _len = table.length; _i < _len; _i++) {
        s = table[_i];
        if (size < s[1]) {
          return "" + ((size / (s[1] / 1024)).toFixed(s[2])) + " " + s[0];
        }
      }
    };
    select_template = "<div class=\"bfmuploader\">\n    <form>\n        <div class=\"button submit\">Upload files</div>\n        <input type=\"file\" class=\"selector\" multiple />\n    </form>\n</div>";
    uploader_template = "<div class=\"uploadinghead\">\n    <div class=\"status\">Uploading&nbsp;(<span class=\"speed\">0 B/s</span>)</div>\n    <div class=\"controls\"><a class=\"icon minimize\"></a></div>\n</div>\n<div class=\"uploading\">\n    <table></table>\n</div>";
    file_template = "<tr>\n    <td class=\"filename\"></td>\n    <td class=\"tight\"><a class=\"icon stop\"></a></td>\n</tr>\n<tr class=\"uploadstatus\"><td colspan=\"2\"><span class=\"progress\"></span></td></tr>";
    uploaded_template = "<a href=\"#\" target=\"_blank\"></a>";
    uploadlist = [];
    uploadable = function(file) {
      var filename, obj;
      obj = {
        file: file,
        el: $(file_template),
        upload: function() {
          var csrf_token;
          csrf_token = $('input[name=csrfmiddlewaretoken]').val();
          return this.xhr = $.ajax_upload(this.file, {
            url: "" + BFMAdminOptions.upload + "?directory=" + BFMAdminOptions.updir,
            headers: {
              "X-CSRFToken": csrf_token
            },
            progress: (__bind(function(e, stats) {
              return this.report_progress(e, stats);
            }, this)),
            complete: (__bind(function(e, data) {
              return this.upload_complete(e, data);
            }, this)),
            error: (__bind(function(e) {
              return this.upload_error(e);
            }, this)),
            abort: (__bind(function(e) {
              return this.upload_abort(e);
            }, this))
          });
        },
        report_progress: function(e, stats) {
          $('.uploadinghead').find('.status .speed').text("" + (readable_size(stats.speed)) + "/s");
          return this.el.find('.progress').stop(true).animate({
            width: "" + (stats.completion * 100) + "%"
          }, stats.last_call);
        },
        upload_complete: function(e, data) {
          this.el.find('.filename').html($(uploaded_template).text(data.filename).attr('href', data.url));
          this.el.find('.progress').stop(true).animate({
            width: "100%"
          }, 300);
          return this.next();
        },
        upload_abort: function(e) {
          this.el.find('.progress').css('background', '#FF6600');
          return this.next();
        },
        upload_error: function(e) {
          this.el.find('.progress').css('background', '#CC0000');
          return this.next();
        }
      };
      filename = obj.file.name != null ? obj.file.name : obj.file.fileName;
      obj.el.find('.filename').text(filename);
      obj.el.find('.stop').click(function(e) {
        return obj.xhr.abort();
      });
      obj.el.appendTo($('.uploading table'));
      return obj;
    };
    uploader = function() {
      var o;
      o = {
        el: $(select_template),
        selected: function(e) {
          var f, file, selected_files, _i, _len;
          this.el = this.el.html($(uploader_template));
          this.el.find('.minimize').click(__bind(function(e) {
            return this.minimize(e);
          }, this));
          selected_files = e.currentTarget.files;
          for (_i = 0, _len = selected_files.length; _i < _len; _i++) {
            file = selected_files[_i];
            f = uploadable(file);
            f.next = __bind(function() {
              uploadlist.shift();
              if (uploadlist.length > 0) {
                return uploadlist[0].upload();
              } else {
                return this.complete();
              }
            }, this);
            uploadlist.push(f);
          }
          return uploadlist[0].upload();
        },
        minimize: function(e) {
          this.el.find('.minimize').removeClass('minimize').addClass('maximize').unbind().click(__bind(function(e) {
            return this.maximize(e);
          }, this));
          this.el.find('.uploading').toggleClass('minimized');
          return this.el.find('.uploadinghead').toggleClass('minimized');
        },
        maximize: function(e) {
          this.el.find('.maximize').addClass('minimize').removeClass('maximize').unbind().click(__bind(function(e) {
            return this.minimize(e);
          }, this));
          this.el.find('.uploading').toggleClass('minimized');
          return this.el.find('.uploadinghead').toggleClass('minimized');
        },
        complete: function() {
          var but;
          but = this.el.find('.minimize') || this.el.find('.maximize');
          return but.removeClass('minimize maximize').addClass('refresh').unbind().click(__bind(function(e) {
            this.el.remove();
            return uploader();
          }, this));
        }
      };
      o.el.appendTo('body');
      return o.el.find('input[type=file]').bind('change', __bind(function(e) {
        return o.selected(e);
      }, this));
    };
    return uploader();
  });
}).call(this);
