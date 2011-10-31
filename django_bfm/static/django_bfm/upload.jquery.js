(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  jQuery.ajax_upload = function(file, options) {
    var $, form, header, progress, readable_size, settings, stats, stats_averages, value, xhr, _ref;
    $ = jQuery;
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
    stats_averages = function(time, loaded) {
      var completion, last_call, size_diff, speed, time_diff;
      stats.push({
        time: time,
        loaded: loaded
      });
      while (time - stats[0].time > 10000) {
        stats.shift();
      }
      time_diff = time - stats[0].time;
      size_diff = loaded - stats[0].loaded;
      speed = ~~((size_diff * 1000 / time_diff) + 0.5);
      completion = loaded / file.size;
      if (completion > 1) {
        completion = 1;
      }
      last_call = time - stats[stats.length - 2].time;
      last_call = last_call + last_call / 10;
      return {
        completion: completion,
        speed: speed,
        last_call: last_call
      };
    };
    progress = function(e) {
      return settings.progress(e, stats_averages(new Date(), e.loaded));
    };
    settings = {
      headers: {
        "X-CSRFToken": null
      },
      url: null,
      progress: function() {},
      complete: function() {},
      error: function() {},
      abort: function() {}
    };
    $.extend(settings, options);
    xhr = new XMLHttpRequest();
    form = new FormData();
    form.append("file", file);
    stats = [
      {
        time: new Date(),
        loaded: 0
      }
    ];
    xhr.upload.addEventListener("progress", (__bind(function(e) {
      return progress(e);
    }, this)), false);
    xhr.addEventListener("load", (__bind(function(e) {
      return settings.complete(e);
    }, this)), false);
    xhr.addEventListener("error", (__bind(function(e) {
      return settings.error(e);
    }, this)), false);
    xhr.addEventListener("abort", (__bind(function(e) {
      return settings.abort(e);
    }, this)), false);
    xhr.open("POST", settings.url);
    _ref = settings.headers;
    for (header in _ref) {
      value = _ref[header];
      xhr.setRequestHeader(header, value);
    }
    xhr.send(form);
    return xhr;
  };
}).call(this);
