(function() {
  var ContextMenu, Dialog, DirectoriesView, Directory, DirectoryBrowser, DirectoryCollection, DirectoryView, File, FileBrowser, FileCollection, FilePaginatorView, FileTableView, FileUploadView, FileUploader, FileView, RootDirectoryView, UploaderView, Urls, directory_upload_support, readable_size,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    _this = this;

  File = Backbone.Model.extend({
    url: 'file/',
    initialize: function() {
      this.set({
        'date': new Date(this.get('date'))
      });
      return this.set({
        'pdate': this.parseDate(),
        'psize': this.parseSize()
      });
    },
    parseDate: function() {
      var d;
      d = this.get("date");
      return "" + (d.getFullYear()) + "-" + (d.getMonth() + 1) + "-" + (d.getDate());
    },
    parseSize: function() {
      return readable_size(this.get('size'));
    },
    delete_file: function() {
      var _this = this;
      return $.ajax({
        url: this.url,
        data: {
          action: 'delete',
          file: this.get('filename'),
          directory: this.get('rel_dir')
        },
        success: function() {
          return FileBrowser.files.remove(_this);
        }
      });
    },
    rename_file: function() {
      var dialog,
        _this = this;
      dialog = new Dialog({
        url: this.url,
        model: this,
        template: '#file_rename_tpl',
        callback: function(data) {
          return _this.rename_file_callback(data);
        }
      });
      return dialog.render();
    },
    rename_file_callback: function(dialog_data) {
      var _this = this;
      return $.ajax({
        url: this.url,
        data: $.extend(dialog_data, {
          action: 'rename'
        }),
        success: function(data) {
          _this.set(JSON.parse(data));
          _this.initialize();
          return FileBrowser.files.sort();
        }
      });
    },
    touch_file: function() {
      var _this = this;
      return $.ajax({
        url: this.url,
        data: {
          action: 'touch',
          file: this.get('filename'),
          directory: this.get('rel_dir')
        },
        success: function(data) {
          _this.set(JSON.parse(data));
          _this.initialize();
          return FileBrowser.files.sort();
        }
      });
    },
    resize_image: function() {
      var dialog;
      dialog = new Dialog({
        url: 'image/',
        model: this,
        template: '#image_resize_tpl',
        callback: function(dialog_data) {
          var _this = this;
          return $.ajax({
            url: 'image/',
            data: $.extend(dialog_data, {
              action: 'resize'
            }),
            success: function(data) {
              FileBrowser.files.add(JSON.parse(data));
              return FileBrowser.files.sort();
            }
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
    }
  });

  FileCollection = Backbone.Collection.extend({
    url: 'list_files/',
    model: File,
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
    initialize: function() {
      this.base_url = this.url;
      this.comparator = this.comparators.date.desc;
      this.bind('reset', this.updated);
      return this.bind('remove', this.updated);
    },
    update_directory: function() {
      return this.url = "" + this.base_url + "?directory=" + FileBrowser.path;
    },
    updated: function() {
      return FileBrowser.paginator.render();
    }
  });

  FileTableView = Backbone.View.extend({
    ord: ['date', true],
    events: {
      'click th': 'resort_data'
    },
    initialize: function() {
      this.el = $('table#result_list');
      return this.delegateEvents(this.events);
    },
    resort_data: function(e) {
      var files, name;
      files = FileBrowser.files;
      name = e.currentTarget.getAttribute('data-name');
      if (!files.comparators[name]) return false;
      if (this.ord[0] === name) {
        this.ord[1] = !this.ord[1];
      } else {
        this.ord = [name, true];
      }
      if (this.ord[1]) {
        files.comparator = files.comparators[name].desc;
      } else {
        files.comparator = files.comparators[name].asc;
      }
      return files.sort();
    },
    render: function(models) {
      var c, tpl,
        _this = this;
      this.current_row = 1;
      this.el.html('');
      this.el.append($('<thead/>').append($('<tr/>')));
      c = {
        filename: '',
        size: '',
        date: '',
        mime: ''
      };
      c[this.ord[0]] = "" + (this.ord[1] ? 'descending' : 'ascending') + " sorted";
      tpl = _.template($('#browse_head_tpl').html(), c);
      this.el.find('tr:first').append(tpl);
      _.forEach(models, function(model) {
        var file;
        file = new FileView({
          'model': model
        });
        return _this.el.append(file.srender());
      });
      return this.delegateEvents(this.events);
    },
    new_row_class: function() {
      this.current_row = (this.current_row + 1) % 2;
      return "row" + (this.current_row + 1);
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
    initialize: function(attrs) {
      this.table = FileBrowser.table;
      this.attrs = attrs.model.attributes;
      return this.model = attrs.model;
    },
    srender: function() {
      var elm, resizable_mimetypes, tpl, _ref;
      tpl = _.template($('#browse_file_tpl').html(), this.attrs);
      elm = $(this.el).html(tpl);
      elm.addClass(this.table.new_row_class());
      resizable_mimetypes = ['image/png', 'image/jpeg', 'image/bmp', 'image/gif'];
      if (!(_ref = this.attrs.mimetype, __indexOf.call(resizable_mimetypes, _ref) >= 0) || !BFMOptions.pil) {
        elm.find('.icons .resize').css('display', 'none');
      }
      return elm;
    },
    "delete": function(e) {
      return this.model.delete_file();
    },
    touch: function(e) {
      return this.model.touch_file();
    },
    rename: function(e) {
      return this.model.rename_file();
    },
    resize: function(e) {
      return this.model.resize_image();
    }
  });

  FilePaginatorView = Backbone.View.extend({
    events: {
      'click a': 'page_click',
      'click .firstpage': 'first_page',
      'click .lastpage': 'last_page'
    },
    initialize: function() {
      this.el = $('p.paginator');
      return this.last_page_count = -1;
    },
    get_page_models: function() {
      var files, page, per_page, start;
      per_page = BFMOptions.files_in_page;
      page = FileBrowser.page;
      files = FileBrowser.files;
      start = per_page * (page - 1);
      return files.models.slice(start, (start + per_page));
    },
    count_pages: function() {
      return ~~(FileBrowser.files.models.length / BFMOptions.files_in_page + 0.99);
    },
    render: function() {
      var page, pages, rn, _ref, _ref2;
      FileBrowser.table.render(this.get_page_models());
      pages = this.count_pages();
      this.el.empty();
      if (pages > 5 && FileBrowser.page > 6) {
        this.el.append(_.template($('#pgn_first_page_tpl').html())());
      }
      for (page = _ref = FileBrowser.page - 5, _ref2 = FileBrowser.page + 5; _ref <= _ref2 ? page <= _ref2 : page >= _ref2; _ref <= _ref2 ? page++ : page--) {
        if (page < 1 || page > pages) continue;
        if (page === FileBrowser.page) {
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
      if (pages > 5 && FileBrowser.page < pages - 5) {
        this.el.append(_.template($('#pgn_last_page_tpl').html())());
      }
      return this.delegateEvents(this.events);
    },
    page_click: function(e) {
      var page;
      page = parseInt($(e.currentTarget).text());
      if (!isNaN(page)) FileBrowser.open_page(page);
      return e.preventDefault();
    },
    first_page: function(e) {
      e.preventDefault();
      return FileBrowser.open_page(1);
    },
    last_page: function(e) {
      e.preventDefault();
      return FileBrowser.open_page(this.count_pages());
    }
  });

  FileBrowser = {
    first: true,
    path: null,
    page: null,
    router: null,
    last_xhr: {
      readyState: 4
    },
    do_browse: function(path, page) {
      var _ref, _ref2;
      if (this.first) {
        this.files = new FileCollection();
        this.table = new FileTableView();
        this.paginator = new FilePaginatorView();
        this.first = false;
      }
      _ref = [path, this.path], this.path = _ref[0], path = _ref[1];
      _ref2 = [parseInt(page), this.page], this.page = _ref2[0], page = _ref2[1];
      if (this.path !== path) {
        this.files.update_directory();
        if (this.last_xhr.readyState !== 4) this.last_xhr.abort();
        return this.last_xhr = this.files.fetch();
      } else if (this.page !== page) {
        return this.paginator.render();
      }
    },
    open_page: function(page) {
      return this.router.navigate("path=" + this.path + "^page=" + page, true);
    }
  };

  Directory = Backbone.Model.extend({
    url: 'directory/',
    initialize: function() {
      this.id = this.get('rel_dir');
      return this.is_child = this.get('rel_dir').indexOf('/') === -1 ? false : true;
    },
    new_folder: function(data) {
      var additional_data;
      additional_data = {
        'action': 'new',
        'directory': this.get('rel_dir')
      };
      return $.ajax({
        'url': this.url,
        'data': $.extend(data, additional_data),
        'success': function() {
          return DirectoryBrowser.directories.fetch();
        }
      });
    },
    rename: function(data) {
      var additional_data;
      additional_data = {
        'action': 'rename',
        'directory': this.get('rel_dir')
      };
      return $.ajax({
        'url': this.url,
        'data': $.extend(data, additional_data),
        'success': function() {
          return DirectoryBrowser.directories.fetch();
        }
      });
    },
    "delete": function(data) {
      return $.ajax({
        url: this.url,
        data: {
          'action': 'delete',
          'directory': this.get('rel_dir')
        },
        success: function() {
          return DirectoryBrowser.directories.fetch();
        }
      });
    }
  });

  DirectoryCollection = Backbone.Collection.extend({
    url: 'list_directories/',
    model: Directory,
    initialize: function(attrs) {
      this.bind('reset', this.added);
      return this.root = new Directory({
        name: '',
        rel_dir: ''
      });
    },
    added: function() {
      var _this = this;
      DirectoryBrowser.sidebar.clear();
      _.forEach(this.models, function(model) {
        if (!model.is_child) {
          return DirectoryBrowser.sidebar.append_directory(model);
        }
      });
      return DirectoryBrowser.sidebar.set_active(DirectoryBrowser.path);
    }
  });

  DirectoriesView = Backbone.View.extend({
    dirs: {},
    active_dir: null,
    initialize: function() {
      this.el = $('.directory-list');
      return new RootDirectoryView();
    },
    append_directory: function(model) {
      var view,
        _this = this;
      view = new DirectoryView({
        'model': model
      });
      this.dirs[model.id] = view;
      this.el.append(view.srender());
      return _.forEach(model.get('children'), function(child) {
        return _this.append_children(child, view);
      });
    },
    append_children: function(id, parent_view) {
      var model, view,
        _this = this;
      model = DirectoryBrowser.directories.get(id);
      view = new DirectoryView({
        'model': model
      });
      this.dirs[model.id] = view;
      parent_view.append_child(view.srender());
      return _.forEach(model.get('children'), function(child) {
        return _this.append_children(child, view);
      });
    },
    set_active: function(path) {
      if (path) {
        if (this.active_dir) this.active_dir.deactivate();
        this.active_dir = this.dirs[path];
        return this.active_dir.activate();
      } else if (this.active_dir) {
        return this.active_dir.deactivate();
      }
    },
    clear: function() {
      var active_dir, dirs;
      dirs = {};
      active_dir = null;
      return this.el.children().remove();
    }
  });

  DirectoryView = Backbone.View.extend({
    tagName: 'li',
    events: {
      "click .directory": "load_directory",
      "contextmenu .directory": "actions_menu"
    },
    children_el: false,
    context_template: '#directory_actions_tpl',
    initialize: function(attrs) {
      var _this = this;
      this.model = attrs.model;
      this.el = $(this.el);
      return this.context_callbacks = [
        (function() {
          return _this.new_folder();
        }), (function() {
          return _this.rename();
        }), (function() {
          return _this["delete"]();
        })
      ];
    },
    load_directory: function(e) {
      e.stopImmediatePropagation();
      e.preventDefault();
      return DirectoryBrowser.open_path(this.model.get('rel_dir'), true);
    },
    srender: function() {
      return this.el.html("<a class='directory'>" + (this.model.get('name')) + "</a>");
    },
    activate: function() {
      return this.el.children('a').addClass('selected');
    },
    deactivate: function() {
      return this.el.children('a').removeClass('selected');
    },
    append_child: function(child) {
      if (!this.children_el) {
        this.children_el = $('<ul />');
        this.el.append(this.children_el);
      }
      return this.children_el.append(child);
    },
    actions_menu: function(e) {
      var entries, menu;
      e.stopImmediatePropagation();
      e.preventDefault();
      entries = $(_.template($(this.context_template).html())());
      menu = new ContextMenu();
      menu.add_entries(entries, this.context_callbacks);
      return menu.render(e);
    },
    new_folder: function() {
      var dialog,
        _this = this;
      dialog = new Dialog({
        'model': this.model,
        'template': '#new_directory_tpl',
        'callback': function(data) {
          return _this.model.new_folder(data);
        }
      });
      return dialog.render();
    },
    rename: function() {
      var dialog,
        _this = this;
      dialog = new Dialog({
        'model': this.model,
        'template': '#rename_directory_tpl',
        'callback': function(data) {
          return _this.model.rename(data);
        }
      });
      return dialog.render();
    },
    "delete": function() {
      var dialog,
        _this = this;
      dialog = new Dialog({
        'model': this.model,
        'template': '#delete_directory_tpl',
        'callback': function(data) {
          return _this.model["delete"](data);
        }
      });
      return dialog.render();
    }
  });

  RootDirectoryView = DirectoryView.extend({
    events: {
      "click a": "load_directory",
      "contextmenu a": "actions_menu"
    },
    context_template: '#rootdirectory_actions_tpl',
    initialize: function() {
      var _this = this;
      this.el = $('#changelist-filter>h2').first();
      this.model = DirectoryBrowser.directories.root;
      this.context_callbacks = [
        (function() {
          return _this.new_folder();
        })
      ];
      return this.delegateEvents();
    }
  });

  DirectoryBrowser = {
    first: true,
    router: null,
    do_browse: function(path) {
      this.path = path;
      if (this.first) {
        this.directories = new DirectoryCollection();
        this.sidebar = new DirectoriesView();
        this.directories.fetch();
        return this.first = false;
      } else {
        return this.sidebar.set_active(path);
      }
    },
    open_path: function(path) {
      return this.router.navigate("path=" + path + "^page=1", true);
    }
  };

  FileUploadView = Backbone.View.extend({
    events: {
      'click .abort': 'abort'
    },
    initialize: function(file) {
      this.file = file;
      return this.directory = FileUploader.path;
    },
    srender: function() {
      var filename;
      filename = this.file.name != null ? this.file.name : this.file.fileName;
      this.el = $(_.template($('#file_upload_tpl').html(), {
        filename: filename
      }));
      this.status = this.el.find('.status');
      this.indicators = {
        'percent': this.el.find('.indicators .percent'),
        'speed': this.el.find('.indicators .speed')
      };
      this.delegateEvents(this.events);
      return this.el;
    },
    do_upload: function() {
      var csrf_token, directory, url,
        _this = this;
      if (this.aborted != null) return false;
      csrf_token = $('input[name=csrfmiddlewaretoken]').val();
      url = "upfile/?directory=" + this.directory;
      if (typeof BFMAdminOptions !== "undefined" && BFMAdminOptions !== null) {
        directory = BFMAdminOptions.upload_rel_dir;
        url = "" + BFMAdminOptions.upload + "?directory=" + directory;
      }
      this.xhr = $.ajax_upload(this.file, {
        'url': url,
        'headers': {
          "X-CSRFToken": csrf_token
        },
        'progress': function(e, stats) {
          return _this.report_progress(e, stats);
        },
        'complete': function(e, data) {
          return _this.upload_complete(e, data);
        },
        'error': function(e) {
          return _this.upload_error(e);
        },
        'abort': function(e) {
          return _this.upload_abort(e);
        }
      });
      this.el.addClass('current');
      return true;
    },
    report_progress: function(e, stats) {
      this.update_status_bar(stats.completion, stats.last_call);
      this.indicators.percent.text(~~(stats.completion * 1000 + 0.5) / 10);
      return this.indicators.speed.text("" + (readable_size(stats.speed)) + "/s");
    },
    upload_complete: function(e, data) {
      var link,
        _this = this;
      this.el.removeClass('current');
      this.el.find('.abort').hide();
      link = $('<a />', {
        'class': 'filename',
        'href': data.url
      });
      link.text(data.filename);
      this.el.find('.filename').replaceWith(link);
      this.update_status_bar(1, 100);
      if (!(typeof BFMAdminOptions !== "undefined" && BFMAdminOptions !== null) && this.directory === FileBrowser.path) {
        _.defer(function() {
          FileBrowser.files.add(data);
          return FileBrowser.files.sort();
        });
      }
      return FileUploader.uploader.report_finished(this);
    },
    upload_abort: function(e) {
      this.el.removeClass('current');
      this.status.css('background', '#FF9F00');
      this.el.find('.indicators').hide();
      this.el.find('.aborted').show();
      this.el.find('.abort').hide();
      return FileUploader.uploader.report_finished(this);
    },
    upload_error: function(e) {
      this.el.removeClass('current');
      this.status.css('background', '#DD4032');
      this.el.find('.indicators').hide();
      this.el.find('.failed').show();
      this.el.find('.abort').hide();
      return FileUploader.uploader.report_finished(this);
    },
    abort: function(e) {
      if (this.xhr != null) {
        return this.xhr.abort();
      } else {
        this.aborted = true;
        this.el.find('.abort').hide();
        this.el.find('.indicators').hide();
        this.el.find('.aborted').show();
        return FileUploader.uploader.finished_uploads.push(this);
      }
    },
    update_status_bar: function(percent, duration) {
      var animation_options, css;
      css = {
        'width': "" + (percent * 100) + "%"
      };
      animation_options = {
        'duration': duration,
        'easing': 'linear'
      };
      return this.status.stop(true).animate(css, animation_options);
    }
  });

  UploaderView = Backbone.View.extend({
    to_upload: [],
    started_uploads: [],
    finished_uploads: [],
    visible: false,
    uploads_at_once: window.BFMOptions.uploads_at_once,
    active_uploads: 0,
    events: {
      'click .uploader-head>.control': 'toggle_visibility',
      'change input[type="file"]': 'add_files',
      'click .finished': 'clear_finished',
      'click .rqueued': 'remove_queue'
    },
    initialize: function() {
      return this.el = $('<div />', {
        'class': 'uploader'
      });
    },
    render: function() {
      this.el.append(_.template($('#uploader_tpl').html()));
      this.el.appendTo($('body'));
      this.height = this.el.height();
      this.width = this.el.width();
      if (directory_upload_support()) {
        this.el.find('.selector.directory').css('display', 'inline-block');
      }
      return this.delegateEvents(this.events);
    },
    toggle_visibility: function(e) {
      var button, css, options;
      button = this.el.find('.uploader-head>.control');
      button.toggleClass('fullscreen exit-fullscreen');
      button.attr = {
        'title': button.attr('data-alttitle'),
        'data-alttitle': button.attr('title')
      };
      options = {
        'duration': 400,
        'queue': false
      };
      css = {
        'width': !this.visible ? '50%' : "" + this.width,
        'height': !this.visible ? '50%' : "" + this.height + "px"
      };
      this.el.animate(css, options);
      this.el.children(':not(.uploader-head)').show();
      return this.visible = !this.visible;
    },
    add_files: function(e) {
      var _this = this;
      return _.forEach(e.currentTarget.files, function(file) {
        return _.defer(function() {
          return _this.add_file(file);
        });
      });
    },
    add_file: function(file) {
      var view,
        _this = this;
      if ((file.name != null ? file.name : file.fileName) === ".") return;
      view = new FileUploadView(file);
      this.to_upload.unshift(view);
      this.el.find('.uploader-table').append(view.srender());
      return _.defer(function() {
        return _this.upload_next();
      });
    },
    upload_next: function() {
      var i, started, upl, _ref;
      for (i = 0, _ref = this.uploads_at_once - this.active_uploads; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        while (this.to_upload.length > 0 && !started) {
          upl = this.to_upload.pop();
          started = upl.do_upload();
          if (started) {
            this.started_uploads.push(upl);
            this.active_uploads += 1;
          }
        }
      }
      if (window.onbeforeunload !== this.unloading && this.active_uploads > 0) {
        return window.onbeforeunload = this.unloading;
      } else {
        return window.onbeforeunload = null;
      }
    },
    report_finished: function(who) {
      var _this = this;
      this.finished_uploads.push(who);
      this.active_uploads -= 1;
      return _.defer(function() {
        return _this.upload_next();
      });
    },
    clear_finished: function(e) {
      var i, _ref, _results,
        _this = this;
      e.preventDefault();
      _results = [];
      for (i = 0, _ref = this.finished_uploads.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        _results.push(_.defer(function() {
          return _this.finished_uploads.pop().remove();
        }));
      }
      return _results;
    },
    remove_queue: function(e) {
      var i, _ref, _results;
      e.preventDefault();
      _results = [];
      for (i = 0, _ref = this.to_upload.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        _results.push(this.to_upload.pop().remove());
      }
      return _results;
    },
    unloading: function() {
      return $.trim($('#upload_cancel_tpl').text());
    }
  });

  FileUploader = {
    init: function() {
      this.uploader = new UploaderView();
      return this.uploader.render();
    },
    do_browse: function(path) {
      return this.path = path;
    }
  };

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

  directory_upload_support = function() {
    var input;
    input = document.createElement('input');
    input.type = "file";
    if ((input.directory != null) || (input.webkitdirectory != null) || (input.mozdirectory != null)) {
      return true;
    }
    return false;
  };

  Dialog = Backbone.View.extend({
    tagName: 'form',
    className: 'dialog',
    events: {
      "click .submit": 'call_callback',
      "click .cancel": 'cancel'
    },
    tear_down: function() {
      var _this = this;
      $(this.el).fadeOut(200, function() {
        return _this.remove();
      });
      return $('.block').fadeOut(200);
    },
    cancel: function(e) {
      this.tear_down();
      return e.preventDefault();
    },
    call_callback: function(e) {
      var field, key, object, _ref;
      this.tear_down();
      e.preventDefault();
      object = {};
      _ref = $(this.el).serializeArray();
      for (key in _ref) {
        field = _ref[key];
        object[field.name] = field.value;
      }
      return this.callback(object);
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
      if (this.hook != null) return this.hook(this);
    }
  });

  ContextMenu = Backbone.View.extend({
    tagName: 'ul',
    className: 'contextmenu',
    initialize: function() {
      return this.el = $(this.el);
    },
    clicked: function(callback) {
      var _this = this;
      this.el.hide(200, function() {
        return _this.remove();
      });
      if (callback != null) return callback();
    },
    add_entry: function(entry, callback) {
      var _this = this;
      this.el.append(entry);
      return $(entry).click(function() {
        return _this.clicked(callback);
      });
    },
    add_entries: function(entries, callbacks) {
      var _this = this;
      entries = entries.filter('li');
      return _.each(entries, function(entry, key) {
        return _this.add_entry(entry, callbacks[key]);
      });
    },
    render: function(e) {
      var left, top, width,
        _this = this;
      width = this.el.appendTo($('body')).outerWidth();
      this.el.hide().show(200);
      top = e.pageY;
      left = e.pageX;
      if (left + width >= $(document).width()) left = $(document).width() - width;
      this.el.css({
        top: top,
        left: left
      });
      return $(document).one('mousedown', function() {
        return _this.clicked();
      });
    }
  });

  Urls = Backbone.Router.extend({
    routes: {
      'path=*path^page=:page': 'do_pass',
      '': 'do_navigate'
    },
    initialize: function() {
      return FileBrowser.router = DirectoryBrowser.router = this;
    },
    do_pass: function(path, page) {
      FileBrowser.do_browse(path, page);
      DirectoryBrowser.do_browse(path);
      FileUploader.do_browse(path);
    },
    do_navigate: function(path) {
      return this.navigate("path=^page=1", true);
    }
  });

  $(function() {
    new Urls();
    FileUploader.init();
    return Backbone.history.start({
      root: BFMRoot
    });
  });

}).call(this);
