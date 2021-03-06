Ajaxer = {
  debug: 0,
  mobileApi: 'index.php',

  // Format of params:
  // params = {
  //   url: 'http://api.lol.com',
  //   data: {sth: 'something', lol: 'laugh out LOUD'}, // Only use if you want a POST request
  //   success: function(data) {
  //     // Do something wth data
  //   },
  //   error: function(jqXHR, text, err) {
  //     // console.lolg "something, something, error"
  //   },
  // }

  getPlainText: function(params) {
    params.dataType = 'text';
    return this.get(params);
  },

  getJson: function(params) {
    params.dataType = 'json';
    return this.get(params);
  },

  getXml: function(params) {
    params.dataType = 'xml';
    return this.get(params);
  },

  getHtml: function(params) {
    params.dataType = 'html';
    return this.get(params);
  },

  getCleanHtml: function(params) {
    params.dataType = 'html';
    params.dataFilter = Ajaxer.cleanHtml;
    return this.get(params);
  },

  get: function(params) {
    if (params === undefined) {
      console.log('ERROR: Params is required. Check ajaxer.js to see format of params.');
      return;
    }
    if (params.url === undefined) {
      console.log('ERROR: URL missing from params.');
      return;
    }
    if (params.dataType === undefined) {
      console.log('ERROR: Do not use Ajaxer.get() directly, use getXml, getJson or one of the others instead.');
      return;
    }
    if (params.success === undefined) {
     console.log('ERROR: Params is missing success function. The success function should use the results for something useful.');
      return;
    }
    if (params.error === undefined) {
     console.log('ERROR: Params is missing error function. Error handling must be in place.');
      return;
    }

    var self = this;
    // Using the constant window.IS_MOBILE here is a small hack
    // which saves a considerable amount of code clutter
    if (window.IS_MOBILE) {
      // Notifier Mobile
      var dataBlob = {};
      dataBlob.url = params.url;
      if (params.data !== undefined) {
        dataBlob.data = params.data;
      }
      return $.ajax({
        type: 'POST',
        data: dataBlob,
        url: self.mobileApi,
        dataFilter: params.dataFilter,
        dataType: params.dataType,
        success: params.success,
        error: params.error,
      });
    }
    else {
      // Notifier
      return $.ajax({
        type: (params.data ? 'POST' : 'GET'),
        data: (params.data ? params.data : ''),
        url: params.url,
        dataFilter: params.dataFilter,
        dataType: params.dataType,
        success: params.success,
        error: params.error,
      });
    }
  },

  // IMPORTANT: This function replaces all <img> tags with <pic>
  cleanHtml: function(html, type) {
    var size = html.length;
    
    // Remove head, links, metas, scripts, iframes, frames, framesets
    html = html.replace(/<head\b[^<]*(?:(?!<\/head>)<[^<]*)*<\/head>/gi, '');
    html = html.replace(/<link\b[^<]*(?:(?!<\/link>)<[^<]*)*<\/link>/gi, '');
    html = html.replace(/<meta\b[^<]*(?:(?!<\/meta>)<[^<]*)*<\/meta>/gi, '');
    html = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    html = html.replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '');
    html = html.replace(/<frame\b[^<]*(?:(?!<\/frame>)<[^<]*)*<\/frame>/gi, '');
    html = html.replace(/<frameset\b[^<]*(?:(?!<\/frameset>)<[^<]*)*<\/frameset>/gi, '');
    
    // Remove audio, video, object, canvas, applet, embed
    html = html.replace(/<audio\b[^<]*(?:(?!<\/audio>)<[^<]*)*<\/audio>/gi, '');
    html = html.replace(/<video\b[^<]*(?:(?!<\/video>)<[^<]*)*<\/video>/gi, '');
    html = html.replace(/<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi, '');
    html = html.replace(/<canvas\b[^<]*(?:(?!<\/canvas>)<[^<]*)*<\/canvas>/gi, '');
    html = html.replace(/<applet\b[^<]*(?:(?!<\/applet>)<[^<]*)*<\/applet>/gi, '');
    html = html.replace(/<embed\b[^<]*(?:(?!<\/embed>)<[^<]*)*<\/embed>/gi, '');
    
    // Remove inline scripts
    html = html.replace(/on\w+\s*?=\s*?("[^"]*"|'[^']*')/gi, '');
    // If any inline scripts didn't use enclosing quotes, turn them into harmless titles
    html = html.replace(/on\w+\s*?=/gi, 'title='); // Note: a bit greedy, but won't cause anything but lulz
    
    // Rename <img> tags to <pic> tags to prevent jQuery from trying to fetch all images.
    // jQuerys behavior is not too problematic, but has some security concerns, also it
    // will most definitely slow down any slow computer running Notifier, like most
    // Infoscreen computers out there.
    // When parsing for images, we will just look for the <pic> tags.
    html = html.replace(/<[\s]*?img/gi, '<pic');
    html = html.replace(/<[\s]*?\/[\s]*?img/gi, '</pic');

    if (Ajaxer.debug) console.log('Ajaxer cleaned HTML, from', size, 'to', html.length);
    return html;
  },
};
