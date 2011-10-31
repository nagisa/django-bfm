(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  $(function() {
    var ChildDirectoriesView, D, Dialog, Directories, DirectoriesView, DirectoryView, Dirs, File, FileTableView, FileUploadView, FileView, Files, Paginator, PaginatorView, Route, Table, Uploader, UploaderView, Urls, readable_size;
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
    File = Backbone.Model.extend({
      initialize: function() {
        this.set({
          'date': new Date(this.get('date'))
        });
        return this.set({
          'pdate': this.parseDate(),
          'psize': this.parseSize()
        });
      },
      delete_file: function() {
        $.ajax({
          url: this.url,
          data: {
            action: 'delete',
            file: this.get('filename'),
            directory: this.get('rel_dir')
          }
        });
        return Route.do_reload = true;
      },
      rename_file: function() {
        var dialog;
        dialog = new Dialog({
          url: this.url,
          model: this,
          template: '#file_rename_tpl',
          callback: this.rename_file_callback
        });
        return dialog.render();
      },
      rename_file_callback: function(dialog_data) {
        return $.ajax({
          url: this.url,
          data: "" + dialog_data + "&action=rename",
          success: __bind(function() {
            return Route.reload();
          }, this)
        });
      },
      touch_file: function() {
        return $.ajax({
          url: this.url,
          data: {
            action: 'touch',
            file: this.get('filename'),
            directory: this.get('rel_dir')
          },
          success: __bind(function() {
            return Route.reload();
          }, this)
        });
      },
      url: 'file/',
      resize_image: function() {
        var dialog;
        dialog = new Dialog({
          url: 'image/',
          model: this,
          template: '#image_resize_tpl',
          callback: function(dialog_data) {
            return $.ajax({
              url: 'image/',
              data: "" + dialog_data + "&action=resize",
              success: __bind(function() {
                return Route.reload();
              }, this)
            });
          },
          hook: function(dialog) {
            $.ajax({
              url: 'image/',
              dataType: 'json',
              data: {
                action: 'info',
                file: dialog.model.get('filename'),
                directory: dialog.model.get('rel_dir')
              },
              success: function(data) {
                $(dialog.el).find('input[name="new_h"]').val(data.height);
                $(dialog.el).find('input[name="new_w"]').val(data.width);
                return $(dialog.el).data('ratio', data.height / data.width);
              }
            });
            $(dialog.el).find('input[name="new_h"]').keyup(function() {
              var h, ratio;
              if ($(dialog.el).find('input[name="keepratio"]').is(':checked')) {
                ratio = $(dialog.el).data('ratio');
                h = $(dialog.el).find('input[name="new_h"]').val();
                return $(dialog.el).find('input[name="new_w"]').val(~~(h / ratio + 0.5));
              }
            });
            return $(dialog.el).find('input[name="new_w"]').keyup(function() {
              var ratio, w;
              if ($(dialog.el).find('input[name="keepratio"]').is(':checked')) {
                ratio = $(dialog.el).data('ratio');
                w = $(dialog.el).find('input[name="new_w"]').val();
                return $(dialog.el).find('input[name="new_h"]').val(~~(w * ratio + 0.5));
              }
            });
          }
        });
        return dialog.render();
      },
      parseDate: function() {
        var d;
        d = this.get("date");
        return "" + (d.getFullYear()) + "-" + (d.getMonth()) + "-" + (d.getDate());
      },
      parseSize: function() {
        return readable_size(this.get('size'));
      }
    });
    Files = Backbone.Collection.extend({
      url: 'list_files/',
      initialize: function(attrs) {
        this.base_url = this.url;
        this.bind('reset', this.added);
        if ((attrs != null) && (attrs.directory != null)) {
          return this.url = this.url + '?directory=' + attrs.directory;
        }
      },
      set_directory: function(directory) {
        return this.url = "" + this.base_url + "?directory=" + directory;
      },
      comparator: function(model) {
        var date, dh, dt;
        date = model.get('date');
        dt = date.getFullYear() * 10000 + date.getMonth() * 100 + date.getDate();
        dh = date.getHours() * 100 + date.getMinutes();
        return -(dt + dh * 0.0001);
      },
      comparators: {
        date: {
          desc: function(model) {
            return 0 - model.get('date');
          },
          asc: function(model) {
            return model.get('date') - 0;
          }
        },
        size: {
          desc: function(model) {
            return -model.get('size');
          },
          asc: function(model) {
            return model.get('size');
          }
        },
        filename: {
          desc: function(model) {
            var str;
            str = model.get("filename");
            str = str.toLowerCase().split("");
            return _.map(str, function(letter) {
              return String.fromCharCode(-(letter.charCodeAt(0)));
            });
          },
          asc: function(model) {
            return model.get("filename");
          }
        },
        mime: {
          desc: function(model) {
            var str;
            str = model.get("mimetype");
            str = str.toLowerCase().split("");
            return _.map(str, function(letter) {
              return String.fromCharCode(-(letter.charCodeAt(0)));
            });
          },
          asc: function(model) {
            return model.get('mimetype');
          }
        }
      },
      model: File,
      models_in_page: BFMOptions.files_in_page,
      get_page: function(page) {
        var end, start;
        page -= 1;
        start = this.models_in_page * page;
        end = start + this.models_in_page;
        return this.models.slice(start, (end + 1) || 9e9);
      },
      page_count: function() {
        return ~~(this.length / this.models_in_page + 1);
      },
      added: function() {
        var page;
        page = Route.page;
        _.forEach(this.get_page(page), function(model) {
          return new FileView({
            'model': model
          }).render();
        });
        return Paginator.render();
      }
    });
    Directories = Backbone.Collection.extend({
      url: 'list_directories/',
      initialize: function(attrs) {
        return this.bind('reset', this.added);
      },
      added: function() {
        return _.forEach(this.models, function(model) {
          return new DirectoryView({
            'model': model.attributes
          }).render();
        });
      }
    });
    FileTableView = Backbone.View.extend({
      el: $('#result_list'),
      current_row: 1,
      ord: ['date', true],
      events: {
        'click th': 'resort_data'
      },
      resort_data: function(e) {
        var name;
        name = e.currentTarget.getAttribute('data-name');
        if (!Files.comparators[name]) {
          return false;
        }
        if (this.ord[0] === name) {
          this.ord[1] = !this.ord[1];
        } else {
          this.ord = [name, true];
        }
        this.clear();
        if (this.ord[1]) {
          Files.comparator = Files.comparators[name].desc;
        } else {
          Files.comparator = Files.comparators[name].asc;
        }
        return Files.sort();
      },
      clear: function() {
        this.current_row = 1;
        this.el.html('');
        this.append($('<thead/>').append($('<tr/>')));
        return this.draw_head();
      },
      append: function(element) {
        return this.el.append(element);
      },
      prepend: function(element) {
        return this.el.prepend(element);
      },
      draw_head: function() {
        var c, tpl;
        c = {
          filename: '',
          size: '',
          date: '',
          mime: ''
        };
        c[this.ord[0]] = "" + (this.ord[1] ? 'descending' : 'ascending') + " sorted";
        tpl = _.template($('#browse_head_tpl').html(), c);
        return this.el.find('tr:first').append(tpl);
      },
      get_row_class: function() {
        this.current_row = (this.current_row + 1) % 2;
        return "row" + (this.current_row + 1);
      }
    });
    DirectoriesView = Backbone.View.extend({
      el: $('.directory-list'),
      append: function(elm) {
        return this.el.append(elm);
      }
    });
    DirectoryView = Backbone.View.extend({
      tagName: 'li',
      events: {
        "click .directory": "load_directory"
      },
      load_directory: function(e) {
        e.stopImmediatePropagation();
        Route.goto(this.model.rel_dir);
        return this.el.children('a').addClass('selected');
      },
      initialize: function(attrs) {
        this.model = attrs.model;
        return this.el = $(this.el);
      },
      render: function() {
        return Dirs.append(this.srender());
      },
      srender: function() {
        var child;
        this.el.html("<a class='directory" + (Route.path === this.model.rel_dir ? " selected" : "") + "'>" + this.model.name + "</a>");
        if (this.model.childs != null) {
          child = new ChildDirectoriesView({
            'childs': this.model.childs,
            'parent': this
          });
          child.render();
        }
        return this.el;
      },
      append: function(element) {
        return this.el.append(element);
      }
    });
    ChildDirectoriesView = Backbone.View.extend({
      tagName: 'ul',
      initialize: function(attrs) {
        this.el = $(this.el);
        this.childs = attrs.childs;
        return this.parent = attrs.parent;
      },
      render: function() {
        var callback;
        callback = function(child) {
          var directory;
          directory = new DirectoryView({
            'model': child
          });
          return this.parent.append(this.el.append(directory.srender()));
        };
        return _.forEach(this.childs, callback, this);
      }
    });
    Dialog = Backbone.View.extend({
      tagName: 'form',
      className: 'dialog',
      events: {
        "click .submit": 'call_callback',
        "click .cancel": 'cancel'
      },
      tear_down: function() {
        $(this.el).fadeOut(200, __bind(function() {
          return this.remove();
        }, this));
        return $('.block').fadeOut(200);
      },
      cancel: function(e) {
        this.tear_down();
        return e.preventDefault();
      },
      call_callback: function(e) {
        this.tear_down();
        e.preventDefault();
        return this.callback($(this.el).serialize());
      },
      initialize: function(attrs) {
        this.url = attrs.url;
        this.model = attrs.model;
        this.template = attrs.template;
        this.callback = attrs.callback;
        return this.hook = attrs.hook;
      },
      render: function() {
        var element, tpl;
        tpl = _.template($(this.template).html(), this.model.attributes);
        element = $(this.el).html(tpl);
        $('body').append(element.fadeIn(200));
        $('.block').fadeIn(300);
        if (this.hook != null) {
          return this.hook(this);
        }
      }
    });
    FileView = Backbone.View.extend({
      tagName: 'tr',
      events: {
        "click .delete": 'delete',
        "click .touch": 'touch',
        "click .rename": 'rename',
        "click .resize": 'resize'
      },
      "delete": function(e) {
        this.model.delete_file();
        return this.remove();
      },
      touch: function(e) {
        return this.model.touch_file();
      },
      rename: function(e) {
        return this.model.rename_file();
      },
      resize: function(e) {
        return this.model.resize_image();
      },
      className: function() {
        return Table.get_row_class();
      },
      initialize: function(attrs) {
        this.table = Table;
        this.attrs = attrs.model.attributes;
        return this.model = attrs.model;
      },
      render: function() {
        var elm, resizable_mimetypes, tpl, _ref;
        tpl = _.template($('#browse_file_tpl').html(), this.attrs);
        elm = $(this.el).html(tpl);
        resizable_mimetypes = ['image/png', 'image/jpeg', 'image/bmp', 'image/gif'];
        if ((_ref = this.attrs.mimetype, __indexOf.call(resizable_mimetypes, _ref) >= 0) && BFMOptions.pil) {
          elm.find('.icons .resize').css('display', 'inline-block');
        }
        return this.table.append(elm);
      }
    });
    FileUploadView = Backbone.View.extend({
      initialize: function(file, parent) {
        this.file = file;
        this.parent = parent;
        return this.directory = Route.path;
      },
      events: {
        'click a': 'abort'
      },
      renders: function() {
        var filename;
        filename = this.file.name != null ? this.file.name : this.file.fileName;
        this.el = $(_.template($('#file_upload_tpl').html(), {
          filename: filename
        }));
        this.delegateEvents(this.events);
        return this.el;
      },
      do_upload: function() {
        var csrf_token;
        csrf_token = $('input[name=csrfmiddlewaretoken]').val();
        return this.xhr = $.ajax_upload(this.file, {
          url: "upfile/?directory=" + this.directory,
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
      abort: function(e) {
        return this.xhr.abort();
      },
      report_progress: function(e, stats) {
        this.parent.report_speed(stats.speed);
        return this.el.find('.progress').stop(true).animate({
          width: "" + (stats.completion * 100) + "%"
        }, stats.last_call);
      },
      upload_error: function(e) {
        this.el.find('.progress').css('background', '#CC0000');
        this.parent.report_errors();
        return this.upload_next();
      },
      upload_abort: function(e) {
        this.el.find('.progress').css('background', '#FF6600');
        return this.upload_next();
      },
      upload_complete: function(e, data) {
        this.el.find('.fname').html("<a href=\"" + data.url + "\" target=\"_blank\">" + data.filename + "</a>");
        this.el.find('.progress').stop(true).animate({
          width: "100%"
        }, 300);
        return this.upload_next();
      },
      upload_next: function() {
        this.parent.upload_next();
        return this.el.find('.stop').remove();
      }
    });
    UploaderView = Backbone.View.extend({
      initialize: function() {
        this.uploadlist = [];
        return this.errors = false;
      },
      el: $('.uploader'),
      events: {
        'change form input': 'selected'
      },
      uploadingevents: {
        'click .minimize': 'minimize',
        'click .maximize': 'maximize',
        'click .refresh': 'rebirth'
      },
      minimize: function(e) {
        this.el.addClass('minimized');
        return $(e.currentTarget).removeClass('minimize').addClass('maximize');
      },
      maximize: function(e) {
        this.el.removeClass('minimized');
        return $(e.currentTarget).removeClass('maximize').addClass('minimize');
      },
      rebirth: function(e) {
        var Uploader;
        Uploader = new UploaderView();
        return Uploader.render(this.el);
      },
      render: function(elm) {
        this.el.html(_.template($('#uploader_start_tpl').html())());
        if (elm != null) {
          return elm.replaceWith(this.el);
        }
      },
      selected: function(e) {
        var file, selected_files, table, tmpl, uploadable, _i, _j, _len, _len2, _ref;
        tmpl = $(_.template($('#uploader_uploading_tpl').html())());
        this.el.replaceWith(tmpl);
        this.el = tmpl;
        this.delegateEvents(this.uploadingevents);
        table = tmpl.find('table');
        selected_files = e.currentTarget.files;
        for (_i = 0, _len = selected_files.length; _i < _len; _i++) {
          file = selected_files[_i];
          this.uploadlist.push(new FileUploadView(file, this));
        }
        _ref = this.uploadlist;
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          uploadable = _ref[_j];
          table.append(uploadable.renders());
        }
        this.uploadlist.reverse();
        this.uploadlist.pop().do_upload();
        return window.onbeforeunload = function(e) {
          return $.trim($('#upload_cancel_tpl').text());
        };
      },
      upload_next: function() {
        var template, text;
        if (this.uploadlist && this.uploadlist.length > 0) {
          return this.uploadlist.pop().do_upload();
        } else {
          template = !this.errors ? '#upload_success_tpl' : '#upload_fail_tpl';
          text = $.trim($(template).text());
          this.el.find('.status').html(text);
          this.el.filter('.uploadinghead').find('.icon').removeClass('minimize maximize').addClass('refresh');
          window.onbeforeunload = null;
          return Route.reload();
        }
      },
      report_speed: function(speed) {
        return this.el.find('.status .speed').text("" + (readable_size(speed)) + "/s");
      },
      report_errors: function() {
        return this.errors = true;
      }
    });
    PaginatorView = Backbone.View.extend({
      el: $('p.paginator'),
      events: {
        'click a': 'page_click',
        'click .firstpage': 'first_page',
        'click .lastpage': 'last_page'
      },
      render: function() {
        var page, page_count, pages, rn, _ref, _ref2;
        this.el.empty();
        pages = [];
        page_count = Files.page_count();
        if (page_count > 5) {
          if (Route.page > 6) {
            this.el.append(_.template($('#pgn_first_page_tpl').html())());
          }
        }
        for (page = _ref = Route.page - 5, _ref2 = Route.page + 5; _ref <= _ref2 ? page <= _ref2 : page >= _ref2; _ref <= _ref2 ? page++ : page--) {
          if (page < 1 || page > page_count) {
            continue;
          }
          if (parseInt(page) === parseInt(Route.page)) {
            rn = _.template($('#pgn_current_page_tpl').html(), {
              page: page
            });
          } else {
            rn = _.template($('#pgn_page_tpl').html(), {
              page: page
            });
          }
          this.el.append(rn);
        }
        if (page_count > 5) {
          if (Route.page < page_count - 5) {
            return this.el.append(_.template($('#pgn_last_page_tpl').html())());
          }
        }
      },
      page_click: function(e) {
        var page;
        page = parseInt($(e.currentTarget).text());
        if (!isNaN(page)) {
          Route.goto(void 0, page);
          return e.preventDefault();
        }
      },
      first_page: function(e) {
        e.preventDefault();
        return Route.goto(void 0, 1);
      },
      last_page: function(e) {
        e.preventDefault();
        return Route.goto(void 0, Files.page_count());
      }
    });
    Urls = Backbone.Router.extend({
      initialize: function() {
        return this.do_reload = false;
      },
      routes: {
        '*path/page-:page': 'do_browse',
        '*path': 'do_browse'
      },
      do_browse: function(path, page) {
        this.page = page != null ? parseInt(page) : 1;
        if (this.do_reload || path !== this.path) {
          this.path = path;
          if (!this.do_reload) {
            Dirs.el.find('.selected').removeClass('selected');
          }
          Table.clear();
          Files.set_directory(path);
          Files.fetch();
        } else {
          Table.clear();
          Files.added();
        }
        return this.do_reload = false;
      },
      goto: function(path, page) {
        page = page != null ? parseInt(page) : 1;
        path = path != null ? path : this.path;
        return this.navigate("" + path + "/page-" + page, true);
      },
      reload: function() {
        this.do_reload = true;
        return this.do_browse(this.path, this.page);
      }
    });
    Table = new FileTableView();
    Dirs = new DirectoriesView();
    Uploader = new UploaderView();
    Paginator = new PaginatorView();
    Files = new Files();
    D = new Directories;
    Route = new Urls();
    D.fetch();
    Uploader.render();
    return Backbone.history.start();
  });
}).call(this);
