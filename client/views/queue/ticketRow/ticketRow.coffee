Template.ticketRow.events
  ### Events for ticket status changes. ###
  'click .ticket-row': (e) ->
    collapsing = $(e.currentTarget).next().find('.accordion-body').attr('aria-expanded')
    $('html, body').clearQueue()
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
    Tickets.update this._id, {$set: {status: $(e.target).html()}}
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')

  'keyup input[name=customStatus]': (e, tpl) ->
    if e.which is 13
      Tickets.update this._id, {$set: {status: $(e.target).val()}}
      $(e.target).val("")
      tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
    
  ### Assigning users to tickets. ###
  'keyup input[name=assignUser]': (e, tpl) ->
    if e.which is 13
      id = Meteor.call 'checkUsername', $(e.target).val(), (err, res) ->
        if res
          tpl.$('[data-toggle="tooltip"]').tooltip('hide')
          Tickets.update tpl.data._id, {$addToSet: {associatedUserIds: res}}
          $(e.target).val('')
        else
          tpl.$('[data-toggle="tooltip"]').tooltip('show')

  'show.bs.collapse': ->
    Meteor.call 'removeFlag', Meteor.userId(), @_id, 'unread'

  ### Hide all tooltips on row collapse and focusout of assign user field. ###
  'hidden.bs.collapse': (e, tpl) ->
    tpl.$('[data-toggle="tooltip"]').tooltip('hide')
    tpl.$('input[name="assignUser"]').val('')

  'focusout input[name="assignUser"]': (e, tpl) ->
    tpl.$('[data-toggle="tooltip"]').tooltip('hide')


Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
  unread: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'unread'})?.v
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'replied'})
  hasAttachment: ->
    TicketFlags.findOne({ticketId: this._id, k: 'attachment'})
