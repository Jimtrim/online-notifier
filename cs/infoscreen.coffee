# Notify Coffeescript that jQuery is here
$ = jQuery
ls = localStorage
iteration = 0

newsLimit = 8 # The most news you can cram into Infoscreen, if other features are disabled

mainLoop = ->
  if DEBUG then console.log "\n#" + iteration

  if Affiliation.org[ls.affiliationKey1].hardwareFeatures
    updateOffice() if iteration % UPDATE_OFFICE_INTERVAL is 0 and ls.showOffice is 'true'
    updateServant() if iteration % UPDATE_SERVANT_INTERVAL is 0 and ls.showOffice is 'true'
    updateMeetings() if iteration % UPDATE_MEETINGS_INTERVAL is 0 and ls.showOffice is 'true'
    updateCoffee() if iteration % UPDATE_COFFEE_INTERVAL is 0 and ls.showOffice is 'true'
  updateCantinas() if iteration % UPDATE_CANTINAS_INTERVAL is 0 and ls.showCantina is 'true'
  updateHours() if iteration % UPDATE_HOURS_INTERVAL is 0 and ls.showCantina is 'true'
  updateBus() if iteration % UPDATE_BUS_INTERVAL is 0 and ls.showBus is 'true'
  updateAffiliationNews '1' if iteration % UPDATE_NEWS_INTERVAL is 0 and ls.showAffiliation1 is 'true' and navigator.onLine # Only if online, otherwise keep old news
  updateAffiliationNews '2' if iteration % UPDATE_NEWS_INTERVAL is 0 and ls.showAffiliation2 is 'true' and navigator.onLine # Only if online, otherwise keep old news
  
  # No reason to count to infinity
  if 10000 < iteration then iteration = 0 else iteration++
  
  setTimeout ( ->
    mainLoop()
  ), PAGE_LOOP

updateOffice = ->
  if DEBUG then console.log 'updateOffice'
  Office.get (status, title, message) ->
    if ls.currentStatus isnt status or ls.currentStatusMessage isnt message
      if status of Office.foods
        $('#office #text').html Office.foods[status].title
        $('#office #text').css 'color', Office.foods[status].color
      else
        $('#office #text').html Office.statuses[status].title
        $('#office #text').css 'color', Office.statuses[status].color
      # $('#office img').attr 'src', 'img/status-'+status+'.png'
      $('#office #subtext').html message
      ls.currentStatus = status
      ls.currentStatusMessage = message

updateServant = ->
  if DEBUG then console.log 'updateServant'
  Servant.get (servant) ->
    $('#todays #schedule #servant').html '- '+servant

updateMeetings = ->
  if DEBUG then console.log 'updateMeetings'
  Meetings.get (meetings) ->
    meetings = meetings.replace /\n/g, '<br />'
    $('#todays #schedule #meetings').html meetings

updateCoffee = ->
  if DEBUG then console.log 'updateCoffee'
  Coffee.get true, (pots, age) ->
    $('#todays #coffee #pots').html '- '+pots
    $('#todays #coffee #age').html age

updateCantinas = ->
  if DEBUG then console.log 'updateCantinas'
  Cantina.get ls.leftCantina, (menu) ->
    cantinaName = Cantina.names[ls.leftCantina]
    $('#cantinas #left .title').html cantinaName
    $('#cantinas #left #dinnerbox').html listDinners(menu)
  Cantina.get ls.rightCantina, (menu) ->
    cantinaName = Cantina.names[ls.rightCantina]
    $('#cantinas #right .title').html cantinaName
    $('#cantinas #right #dinnerbox').html listDinners(menu)

listDinners = (menu) ->
  dinnerlist = ''
  # If menu is just a message, not a menu: (yes, a bit hackish, but reduces complexity in the cantina script)
  if typeof menu is 'string'
    ls.noDinnerInfo = 'true'
    dinnerlist += '<li>' + menu + '</li>'
  else
    ls.noDinnerInfo = 'false'
    for dinner in menu
      if dinner.price != null
        dinner.price = dinner.price + ',-'
        dinnerlist += '<li id="' + dinner.index + '">' + dinner.price + ' ' + dinner.text + '</li>'
      else
        dinnerlist += '<li class="message" id="' + dinner.index + '">"' + dinner.text + '"</li>'
  return dinnerlist

updateHours = ->
  if DEBUG then console.log 'updateHours'
  Hours.get ls.leftCantina, (hours) ->
    $('#cantinas #left .hours').html hours
  Hours.get ls.rightCantina, (hours) ->
    $('#cantinas #right .hours').html hours

updateBus = ->
  if DEBUG then console.log 'updateBus'
  if !navigator.onLine
    $('#bus #firstBus .name').html ls.firstBusName
    $('#bus #secondBus .name').html ls.secondBusName
    $('#bus #firstBus .first .line').html '<div class="error">Frakoblet fra api.visuweb.no</div>'
    $('#bus #secondBus .first .line').html '<div class="error">Frakoblet fra api.visuweb.no</div>'
  else
    createBusDataRequest('firstBus', '#firstBus')
    createBusDataRequest('secondBus', '#secondBus')

createBusDataRequest = (bus, cssIdentificator) ->
  activeLines = ls[bus+'ActiveLines'] # array of lines stringified with JSON (hopefully)
  activeLines = JSON.parse activeLines
  # Get bus data, if activeLines is an empty array we'll get all lines, no problemo :D
  Bus.get ls[bus], activeLines, (lines) ->
    insertBusInfo lines, ls[bus+'Name'], cssIdentificator

insertBusInfo = (lines, stopName, cssIdentificator) ->
  busStop = '#bus '+cssIdentificator
  spans = ['first', 'second', 'third', 'fourth']

  $(busStop+' .name').html stopName

  # Reset spans
  for i of spans
    $(busStop+' .'+spans[i]+' .line').html ''
    $(busStop+' .'+spans[i]+' .time').html ''
  
  if typeof lines is 'string'
    # Lines is an error message
    $(busStop+' .first .line').html '<div class="error">'+lines+'</div>'
  else
    # No lines to display, busstop is sleeping
    if lines['departures'].length is 0
      $(busStop+' .first .line').html '<div class="error">....zzzZZZzzz....<br />(etter midnatt vises ikke)</div>'
    else
      # Display line for line with according times
      for i of spans
        # Add the current line
        $(busStop+' .'+spans[i]+' .line').append lines['destination'][i]
        $(busStop+' .'+spans[i]+' .time').append lines['departures'][i]

updateAffiliationNews = (number) ->
  if DEBUG then console.log 'updateAffiliationNews'+number
  # Detect selector
  selector = if number is '1' then '#left' else '#right'
  if ls.showAffiliation2 isnt 'true' then selector = '#full'
  # Get affiliation object
  affiliationKey = ls['affiliationKey'+number]
  affiliation = Affiliation.org[affiliationKey]
  if affiliation is undefined
    if DEBUG then console.log 'ERROR: chosen affiliation', ls['affiliationKey'+number], 'is not known'
  else
    # Get more news than needed to check for old news that have been updated
    newsLimit = 10
    News.get affiliation, newsLimit, (items) ->
      # Error message (log it maybe), or zero items in news feed
      if typeof items is 'string' or items.length is 0
        if DEBUG then console.log 'ERROR:', items
        key = ls['affiliationKey'+number]
        name = Affiliation.org[key].name
        $('#news '+selector).html '<div class="post"><div class="title">Nyheter</div><div class="item">Frakoblet fra '+name+'</div></div>'
      # News is here! NEWS IS HERE! FRESH FROM THE PRESS!
      else
        newsList = 'affiliationNewsList'+number
        ls[newsList] = News.refreshNewsList items
        displayItems items, selector, 'affiliationNewsList'+number, 'affiliationViewedList'+number, 'affiliationUnreadCount'+number

displayItems = (items, column, newsListName, viewedListName, unreadCountName) ->
  # Empty the news column
  $('#news '+column).html ''
  # Get feedkey
  feedKey = items[0].feedKey

  # Get list of last viewed items and check for news that are just
  # updated rather than being actual news
  newsList = JSON.parse ls[newsListName]
  viewedList = JSON.parse ls[viewedListName]
  updatedList = findUpdatedPosts newsList, viewedList

  # Build list of last viewed for the next time the user views the news
  viewedList = []

  # Add feed items to popup
  $.each items, (index, item) ->
    
    if index < newsLimit
      viewedList.push item.link
      
      unreadCount = Number ls[unreadCountName]
      readUnread = ''
      if index < unreadCount
        if item.link in updatedList.indexOf
          readUnread += '<span class="unread">UPDATED <b>::</b> </span>'
        else
          readUnread += '<span class="unread">NEW <b>::</b> </span>'

      # EXPLANATION NEEDED:
      # .item[data] contains the link
      # .item[name] contains the alternative link, if one exists, otherwise null
      date = altLink = ''
      if item.altLink isnt null
        altLink = ' name="' + item.altLink + '"'
      if item.date isnt null and ls.showAffiliation2 is 'false'
        date = ' den ' + item.date
      descLimit = 140
      if ls.showAffiliation2 is 'true'
        descLimit = 100
      if item.description.length > descLimit
        item.description = item.description.substr(0, descLimit) + '...'

      htmlItem = '
        <div class="post">
          <div class="item" data="' + item.link + '"' + altLink + '>
            <div class="title">' + readUnread + item.title + '</div>
            <img src="' + item.image + '" width="107" />
            ' + item.description + '
            <div class="author">&ndash; Av ' + item.creator + date + '</div>
          </div>
        </div>'
      $('#news '+column).append htmlItem
  
  # Store list of last viewed items
  ls[viewedListName] = JSON.stringify viewedList

  # All items are now considered read
  Browser.setBadgeText ''
  ls[unreadCountName] = 0

  # Make news items open extension website while closing popup
  $('.item').click ->
    # The link is embedded as the ID of the element, we don't want to use
    # <a> anchors because it creates an ugly box marking the focus element.
    # Note that altLinks are embedded in the name-property of the element,
    # - if preferred by the organization, we should use that instead.
    altLink = $(this).attr 'name'
    useAltLink = Affiliation.org[ls.affiliationKey1].useAltLink
    if altLink isnt undefined and useAltLink is true
      Browser.openTab $(this).attr 'name'
    else
      Browser.openTab $(this).attr 'data'
    window.close()

  # If organization prefers alternative links, use them
  if Affiliation.org[feedKey].useAltLink
    altLink = $('.item[data="'+link+'"]').attr 'name'
    if altLink isnt 'null'
      $('.item[data="'+link+'"]').attr 'data', altLink

  # If the organization has it's own getImage function, use it
  if Affiliation.org[feedKey].getImage isnt undefined
    for index, link of viewedList
      # It's important to get the link from the callback within the function below,
      # not the above code, - because of race conditions mixing up the news posts, async ftw.
      Affiliation.org[feedKey].getImage link, (link, image) ->
        # Also, check whether there's already a qualified image before replacing it.
        if ($('.item[data="'+link+'"] img').attr('src').indexOf('http') == -1)
          $('.item[data="'+link+'"] img').attr 'src', image

  # If the organization has it's own getImages (plural) function, use it
  if Affiliation.org[feedKey].getImages isnt undefined
    Affiliation.org[feedKey].getImages viewedList, (links, images) ->
      for index of links
        if ($('.item[data="'+links[index]+'"] img').attr('src').indexOf('http') == -1)
          $('.item[data="'+links[index]+'"] img').attr 'src', images[index]

# Checks the most recent list of news against the most recently viewed list of news
findUpdatedPosts = (newsList, viewedList) ->
  updatedList = []
  # Compare lists, keep your mind straight here:
  # Updated news are:
  # - saved in the newsList before the first identical item in the viewedList
  # - saved in the viewedList after the first identical item in the newsList
  for i of newsList
    break if newsList[i] is viewedList[0]
    for j of viewedList
      continue if j is 0
      if newsList[i] is viewedList[j]
        updatedList.push newsList[i]
  return updatedList

officeFontRotate = (font) ->
  fonts = ['fondamento','mysteryquest','oleoscript','sancreek']
  if font in fonts
    chosenFont = font
  else
    chosenFont = fonts[Math.floor(Math.random() * fonts.length)]
  $('#office #text').prop 'class', chosenFont
  if DEBUG
    $('#office #subtext').html ls.currentStatusMessage + '<br />' + chosenFont

changeCreatorName = (name) ->
  # Stop previous changeCreatorName instance, if any
  clearTimeout ls.changeCreatorNameTimeoutId
  # Animate creator name change in the pageflip
  animateCreatorName name

animateCreatorName = (name, build) ->
  # Animate it
  text = $('#pagefliptyping').text()
  if text.length is 0
    build = true
    name = name + " with <3"
  random = Math.floor 350 * Math.random() + 50
  if !build
    $('#pagefliptyping').text text.slice 0, text.length-1
    ls.animateCreatorNameTimeoutId = setTimeout ( ->
      animateCreatorName name
    ), random
  else
    if text.length isnt name.length
      if text.length is 0
        $('#pagefliptyping').text name.slice 0, 1
      else
        $('#pagefliptyping').text name.slice 0, text.length+1
      ls.animateCreatorNameTimeoutId = setTimeout ( ->
        animateCreatorName name, true
      ), random

# Document ready, go!
$ ->
  if DEBUG
    # show the cursor and remove the overlay (the gradient at the bottom)
    # (allows DOM inspection with the mouse)
    $('html').css 'cursor', 'auto'
    $('#overlay').hide()
  
  # Setting the timeout for all AJAX and JSON requests
  $.ajaxSetup AJAX_SETUP
  
  # Clear all previous thoughts
  ls.removeItem 'currentStatus'
  ls.removeItem 'currentStatusMessage'

  # If only one affiliation is to be shown remove the second news column
  if ls.showAffiliation2 isnt 'true'
    $('#news #right').hide()
    $('#news #left').attr 'id', 'full'
    # Who uses single affiliations?
    if !DEBUG then _gaq.push(['_trackEvent', 'infoscreen', 'loadSingleAffiliation', ls.affiliationKey1])
    # What is the prefered primary affiliation?
    if !DEBUG then _gaq.push(['_trackEvent', 'infoscreen', 'loadAffiliation1', ls.affiliationKey1])
  else
    # What kind of double affiliations are used?
    if !DEBUG then _gaq.push(['_trackEvent', 'infoscreen', 'loadDoubleAffiliation', ls.affiliationKey1 + ' - ' + ls.affiliationKey2])
    # What is the prefered primary affiliation?
    if !DEBUG then _gaq.push(['_trackEvent', 'infoscreen', 'loadAffiliation1', ls.affiliationKey1])
    # What is the prefered secondary affiliation?
    if !DEBUG then _gaq.push(['_trackEvent', 'infoscreen', 'loadAffiliation2', ls.affiliationKey2])

  # Hide stuff that the user has disabled in options
  $('#office').hide() if ls.showOffice isnt 'true'
  $('#todays').hide() if ls.showOffice isnt 'true'
  $('#cantinas').hide() if ls.showCantina isnt 'true'
  $('#bus').hide() if ls.showBus isnt 'true'

  if DEBUG then console.log 'Applying affiliation graphics'
  key = ls.affiliationKey1
  logo = Affiliation.org[key].logo
  icon = Affiliation.org[key].icon
  placeholder = Affiliation.org[key].placeholder
  sponsor = Affiliation.org[key].sponsor
  if sponsor isnt undefined
    $('#logo').prop 'src', sponsor
  else
    $('#logo').prop 'src', logo
  $('link[rel="shortcut icon"]').attr 'href', icon
  $('#news .post img').attr 'src', placeholder

  # Track popularity of the chosen palette, the palette itself is loaded a lot earlier for perceived speed
  if !DEBUG then _gaq.push(['_trackEvent', 'infoscreen', 'loadPalette', ls.affiliationPalette])
  
  # Minor esthetical adjustments for OS version
  if OPERATING_SYSTEM == 'Windows'
    $('#pagefliptext').attr "style", "bottom:9px;"
    $('#pagefliplink').attr "style", "bottom:9px;"
  # Adding creator name to pageflip
  changeCreatorName ls.extensionCreator
  # Blinking cursor at pageflip
  setInterval ( ->
    $(".pageflipcursor").animate opacity: 0, "fast", "swing", ->
      $(@).animate opacity: 1, "fast", "swing",
  ), 600

  # Randomize font in the office status
  officeFontRotate()
  setInterval ( ->
    officeFontRotate()
  ), 3000

  # Start the clock in #bus, from: alessioatzeni.com/blog/css3-digital-clock-with-jquery/
  setInterval ( ->
    _d = new Date()
    minutes = _d.getMinutes()
    hours = _d.getHours()
    # Pad the number with a zero if less than 10
    if minutes < 10 then minutes = '0' + minutes
    if hours < 10 then hours = '0' + hours
    $("#bus #clock #minutes").html minutes
    $("#bus #clock #hours").html hours
  ), 1000

  # Prevent image burn-in by fading to black every half hour
  setInterval ( ->
    random = Math.ceil Math.random() * 25
    linebreaks = ('<br />' for num in [0..random]).join(' ')
    $('#overlay').html linebreaks + 'preventing image burn-in...'
    $('#overlay').css 'opacity', 1
    setTimeout ( ->
      $('#overlay').css 'opacity', 0
    ), 3500
  ), 1800000

  # Enter main loop, keeping everything up-to-date
  mainLoop()