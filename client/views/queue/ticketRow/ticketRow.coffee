Template.ticketRow.events
  ### Events for ticket status changes. ###
  'click .ticket-row': (e) ->
    collapsing = $(e.currentTarget).next().find('.accordion-body').attr('aria-expanded')
    $('html, body').clearQueue()
    unless _.contains($(e.target)[0].classList, 'dropdown-toggle')
      if collapsing is 'true'
        $('html, body').animate({scrollTop: $(e.currentTarget).offset().top - $(window).height()/2}, 600)
      else
        target = $(e.currentTarget)
        Meteor.setTimeout ->
          $('html, body').animate({scrollTop: target.offset().top}, 375)
        , 200
  'click .dropdown-menu[name=statusMenu]': (e, tpl) ->
    e.stopPropagation() #Stops table row expanding on dropdown click. Have to trigger dropdown manually below.
  'click .dropdown-menu[name=statusMenu] a': (e, tpl) ->
    unless @status is $(e.target).html()
      Tickets.update @_id, {$set: {status: $(e.target).html()}}
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')

  'keyup input[name=customStatus]': (e, tpl) ->
    if e.which is 13
      Tickets.update @_id, {$set: {status: $(e.target).val()}}
      $(e.target).val("")
      tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
    
  'show.bs.collapse': (e, tpl) ->
    Meteor.call 'removeFlag', Meteor.userId(), @_id, 'unread'
    tpl.$('span[name=plusminus]').removeClass('glyphicon-plus').addClass('glyphicon-minus')


  ### Hide all tooltips on row collapse and focusout of assign user field. ###
  'hide.bs.collapse': (e, tpl) ->
    tpl.$('[data-toggle="tooltip"]').tooltip('hide')
    tpl.$('input[name="assignUser"]').val('')
    tpl.$('span[name=plusminus]').removeClass('glyphicon-minus').addClass('glyphicon-plus')

  'focusout input[name="assignUser"]': (e, tpl) ->
    tpl.$('[data-toggle="tooltip"]').tooltip('hide')


Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  bodyParagraph: ->
    @body.split('\n')
  changelog: ->
    Changelog.find {ticketId: @_id}, {sort: timestamp: 1}
  unread: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: @_id, k: 'unread'})?.v
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: @_id, k: 'replied'})
  hasAttachment: ->
    @attachmentIds?.length > 0
