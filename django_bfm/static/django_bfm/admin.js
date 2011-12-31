(function() {
  var ContextMenu, Dialog, FileUploadView, FileUploader, UploaderView, directory_upload_support, readable_size;

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

  FileUploader.init();

  FileUploader.do_browse('');

}).call(this);
