// Generated by CoffeeScript 1.4.0
(function() {
  var $, iteration, ls, mainLoop, updateCoffeeSubscription, updateNews, updateOfficeAndMeetings;

  $ = jQuery;

  ls = localStorage;

  iteration = 0;

  mainLoop = function() {
    var loopTimeout;
    if (DEBUG) {
      console.log("\n#" + iteration);
    }
    if (ls.useInfoscreen !== 'true') {
      if (iteration % UPDATE_OFFICE_INTERVAL === 0 && ls.showOffice === 'true') {
        updateOfficeAndMeetings();
      }
      if (iteration % UPDATE_COFFEE_INTERVAL === 0 && ls.coffeeSubscription === 'true') {
        updateCoffeeSubscription();
      }
      if (iteration % UPDATE_NEWS_INTERVAL === 0 && navigator.onLine) {
        updateNews();
      }
    }
    if (10000 < iteration) {
      iteration = 0;
    } else {
      iteration++;
    }
    if (DEBUG || !navigator.onLine || ls.currentStatus === 'error') {
      loopTimeout = BACKGROUND_LOOP_QUICK;
    } else {
      loopTimeout = BACKGROUND_LOOP;
    }
    return setTimeout((function() {
      return mainLoop();
    }), loopTimeout);
  };

  updateOfficeAndMeetings = function() {
    if (DEBUG) {
      console.log('updateOfficeAndMeetings');
    }
    return Office.get(function(status, title, message) {
      if (ls.currentStatus !== status || ls.currentStatusMessage !== message) {
        Browser.setIcon('img/icon-' + status + '.png');
        ls.currentStatus = status;
        return Meetings.get(function(meetings) {
          var today;
          today = '### Nå\n' + title + ": " + message + "\n### Resten av dagen\n" + meetings;
          Browser.setTitle(today);
          return ls.currentStatusMessage = message;
        });
      }
    });
  };

  updateCoffeeSubscription = function() {
    if (DEBUG) {
      console.log('updateCoffeeSubscription');
    }
    return Coffee.get(false, function(pots, age) {
      var storedPots;
      pots = Number(pots);
      console.log('pots', pots, 'age', age);
      if (!isNaN(pots)) {
        storedPots = Number(ls.coffeePots);
        if (storedPots < pots) {
          console.log('- new pot!! meeting?');
          if (ls.currentStatus !== 'meeting') {
            console.log('-- not meetings!!!! near in time?');
            if (age.match(/\d:\d/g === null)) {
              console.log('--- NEAR IN TIME! OMFGOMFG KAFFE!!!!!!!!');
              Coffee.showNotification(pots);
            } else {
              console.log('------------------ old coffee is old :(');
            }
          }
        }
        return ls.coffeePots = pots;
      }
    });
  };

  updateNews = function() {
    var newsLimit;
    if (DEBUG) {
      console.log('updateNews');
    }
    newsLimit = 4;
    return News.get('online', newsLimit, function(items) {
      if (items !== null) {
        return News.unreadCount(items);
      } else {
        if (DEBUG) {
          return console.log('ERROR: News did not reach us');
        }
      }
    });
  };

  $(function() {
    var firstBusOk, first_bus_props, prop, secondBusOk, second_bus_props, _i, _j, _len, _len1;
    $.ajaxSetup({
      timeout: AJAX_TIMEOUT
    });
    if (DEBUG) {
      ls.clear();
    }
    ls.removeItem('currentStatus');
    ls.removeItem('currentStatusMessage');
    if (ls.showBus === void 0) {
      ls.showBus = 'true';
    }
    first_bus_props = [ls.first_bus, ls.first_bus_name, ls.first_bus_direction, ls.first_bus_active_lines, ls.first_bus_inactive_lines];
    second_bus_props = [ls.second_bus, ls.second_bus_name, ls.second_bus_direction, ls.second_bus_active_lines, ls.second_bus_inactive_lines];
    firstBusOk = true;
    secondBusOk = true;
    for (_i = 0, _len = first_bus_props.length; _i < _len; _i++) {
      prop = first_bus_props[_i];
      if (prop === void 0) {
        firstBusOk = false;
      }
    }
    for (_j = 0, _len1 = second_bus_props.length; _j < _len1; _j++) {
      prop = second_bus_props[_j];
      if (prop === void 0) {
        secondBusOk = false;
      }
    }
    if (!firstBusOk) {
      ls.first_bus = 16011333;
      ls.first_bus_name = 'Gløshaugen Nord';
      ls.first_bus_direction = 'til byen';
      ls.first_bus_active_lines = JSON.stringify([5, 22]);
      ls.first_bus_inactive_lines = JSON.stringify([169]);
    }
    if (!secondBusOk) {
      ls.second_bus = 16010333;
      ls.second_bus_name = 'Gløshaugen Nord';
      ls.second_bus_direction = 'fra byen';
      ls.second_bus_active_lines = JSON.stringify([5, 22]);
      ls.second_bus_inactive_lines = JSON.stringify([169]);
    }
    if (ls.showOffice === void 0) {
      ls.showOffice = 'true';
    }
    if (ls.showCantina === void 0) {
      ls.showCantina = 'true';
    }
    if (ls.left_cantina === void 0) {
      ls.left_cantina = 'hangaren';
    }
    if (ls.right_cantina === void 0) {
      ls.right_cantina = 'realfag';
    }
    if (ls.openChatter === void 0) {
      ls.openChatter = 'false';
    }
    if (ls.showNotifications === void 0) {
      ls.showNotifications = 'true';
    }
    if (ls.coffeeSubscription === void 0) {
      ls.coffeeSubscription = 'true';
    }
    if (ls.coffeePots === void 0) {
      ls.coffeePots = 0;
    }
    if (ls.useInfoscreen === void 0) {
      ls.useInfoscreen = 'false';
    }
    if (ls.everConnected === void 0 && !DEBUG) {
      Browser.openTab('options.html');
    }
    if (ls.useInfoscreen === 'true') {
      Browser.openTab('infoscreen.html');
    }
    if (ls.openChatter === 'true') {
      Browser.openBackgroundTab('http://webchat.freenode.net/?channels=online');
    }
    ls.everConnected = ls.wasConnected = 'false';
    setInterval((function() {
      return document.location.reload();
    }), 86400000);
    return mainLoop();
  });

}).call(this);
