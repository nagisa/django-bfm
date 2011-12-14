(function() {
  var Dialog, FileUploadView, FileUploader, UploaderView, directory_upload_support, readable_size;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
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
        percent: this.el.find('.indicators .percent'),
        speed: this.el.find('.indicators .speed')
      };
      this.delegateEvents(this.events);
      return this.el;
    },
    do_upload: function() {
      var csrf_token, url;
      if (this.aborted != null) {
        return false;
      }
      csrf_token = $('input[name=csrfmiddlewaretoken]').val();
      url = "upfile/?directory=" + this.directory;
      if (typeof BFMAdminOptions !== "undefined" && BFMAdminOptions !== null) {
        url = "" + BFMAdminOptions.upload + "?directory=" + this.directory;
      }
      this.xhr = $.ajax_upload(this.file, {
        url: url,
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
      this.el.addClass('current');
      return true;
    },
    report_progress: function(e, stats) {
      this.update_status_bar(stats.completion, stats.last_call);
      this.indicators.percent.text(~~(stats.completion * 1000 + 0.5) / 10);
      return this.indicators.speed.text("" + (readable_size(stats.speed)) + "/s");
    },
    upload_complete: function(e, data) {
      var link;
      this.el.removeClass('current');
      this.el.find('.abort').hide();
      link = $('<a />', {
        "class": 'filename',
        href: data.url
      }).text(data.filename);
      this.el.find('.filename').replaceWith(link);
      this.update_status_bar(1, 100);
      if (!(typeof BFMAdminOptions !== "undefined" && BFMAdminOptions !== null)) {
        FileBrowser.files.fetch();
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
        duration: duration,
        easing: 'linear'
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
        "class": 'uploader'
      });
    },
    render: function() {
      this.el.append(_.template($('#uploader_tpl').html()));
      this.el.appendTo($('body'));
      this.height = this.el.height();
      if (directory_upload_support()) {
        this.el.find('.selector.directory').show();
      }
      return this.delegateEvents(this.events);
    },
    toggle_visibility: function(e) {
      var button, css, options, others;
      button = this.el.find('.uploader-head>.control');
      button.toggleClass('fullscreen exit-fullscreen');
      button.attr({
        'title': button.attr('data-alttitle'),
        'data-alttitle': button.attr('title')
      });
      options = {
        duration: 400,
        queue: false
      };
      if (!this.visible) {
        css = {
          width: '50%',
          height: '50%'
        };
      } else {
        css = {
          width: '162px',
          height: "" + this.height + "px"
        };
      }
      this.el.animate(css, options);
      others = this.el.children(':not(.uploader-head)').stop(true, true);
      others.fadeToggle(options.duration);
      return this.visible = !this.visible;
    },
    add_files: function(e) {
      return _.forEach(e.currentTarget.files, __bind(function(file) {
        return _.delay((__bind(function(file) {
          return this.add_file(file);
        }, this)), 0, file);
      }, this));
    },
    add_file: function(file) {
      var view;
      if ((file.name != null ? file.name : file.fileName) === ".") {
        console.log("directory suppressed...");
        return;
      }
      view = new FileUploadView(file);
      this.to_upload.unshift(view);
      this.el.find('.uploader-table').append(view.srender());
      return this.upload_next();
    },
    upload_next: function() {
      var i, started, upl, _ref, _results;
      _results = [];
      for (i = 0, _ref = this.uploads_at_once - this.active_uploads; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        _results.push((function() {
          var _results2;
          _results2 = [];
          while (this.to_upload.length > 0 && !started) {
            upl = this.to_upload.pop();
            started = upl.do_upload();
            this.started_uploads.push(upl);
            _results2.push(this.active_uploads += 1);
          }
          return _results2;
        }).call(this));
      }
      return _results;
    },
    report_finished: function(who) {
      this.finished_uploads.push(who);
      this.active_uploads -= 1;
      return this.upload_next();
    },
    clear_finished: function(e) {
      var i, _ref, _results;
      e.preventDefault();
      _results = [];
      for (i = 0, _ref = this.finished_uploads.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        _results.push(_.defer(__bind(function() {
          return this.finished_uploads.pop().remove();
        }, this)));
      }
      return _results;
    },
    remove_queue: function(e) {
      var i, _ref, _results;
      e.preventDefault();
      _results = [];
      for (i = 0, _ref = this.to_upload.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        _results.push(_.defer(__bind(function() {
          return this.to_upload.pop().remove();
        }, this)));
      }
      return _results;
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
