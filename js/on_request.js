// Recieve all requests from parts of the extension that cannot access
// localStorage or the rest of the codebase. Example: A content script.
function onRequest(request, sender, callback) {
  console.log(request)
  if (request == 'resetCounterWhenOnWebsite' || request.action == 'resetCounterWhenOnWebsite') {
    localStorage.unreadCount = 0;
    localStorage.mostRecentRead = localStorage.mostRecentUnread;
    Browser.setBadgeText('');
  }
  // else if (request.action == 'getChosenDinner') {
  //   var chosenDinner = localStorage.chosenDinner;
  //   localStorage.removeItem("chosenDinner");
  //   callback(chosenDinner);
  // }
  // else if (request.action == 'showCantina') {
  //   callback(localStorage.showCantina);
  // }
  // else if (request.action == 'dismissSitNotice') {
  //   localStorage.dismissedSitNotice = 'true';
  //   callback(true);
  // }
  // else if (request.action == 'dismissedSitNotice') {
  //   callback(localStorage.dismissedSitNotice);
  // }
  else if (DEBUG) console.log('ERROR: unrecognized request');
}

// wire up the onRequest listener function
if (BROWSER == "Chrome")
  chrome.extension.onRequest.addListener(onRequest);
else if (BROWSER == "Opera")
  opera.extension.onmessage = function(event) {
    window.opera.postError('Received message from base.js');
    // got the URL from the injected script
    if (event.data == 'resetCounterWhenOnWebsite') {
      Browser.setBadgeText('!!');
    }
    var message = event.data;
    onRequest({'action':message});
  };