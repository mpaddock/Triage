Template.ticketRow.events
  'click .ticket-row': (e) ->
    Blaze.renderWithData Template.ticketModal, @, $('body').get(0)
    $('#ticketModal').modal('show')

  'click .dropdown-menu[name=statusMenu] a': (e, tpl) ->
    unless @status is $(e.target).html()
      Tickets.update @_id, {$set: {status: $(e.target).html()}}
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
  
  'autocompleteselect input[name=customStatus]': (e, tpl, doc) ->
    Tickets.update tpl.data._id, { $set: { status: doc.name } }
    $(e.target).val("")
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')

  'keyup input[name=customStatus]': (e, tpl) ->
    if e.which is 13
      Tickets.update tpl.data._id, { $set: { status: $(e.target).val() } }
      $(e.target).val("")
      tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
    
  'show.bs.collapse .ticket-collapse': (e, tpl) ->
    if _.contains $(e.target)[0].classList, 'ticket-collapse'
      Meteor.call 'removeFlag', Meteor.userId(), @_id, 'unread'
      tpl.$('span[name=plusminus]').removeClass('glyphicon-plus').addClass('glyphicon-minus')

Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  queueMember: ->
    _.contains Queues.findOne({name: @queueName}).memberIds, Meteor.userId()
  changelog: ->
    Changelog.find {ticketId: @_id}, {sort: timestamp: 1}
  unread: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: @_id, k: 'unread'})?.v
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: @_id, k: 'replied'})
  hasAttachment: ->
    @attachmentIds?.length > 0
  noteCount: ->
    Changelog.find({ ticketId: @_id, type: "note" }).count() || null # No badge instead of '0' badge
  statusSettings: ->
    {
      position: "bottom"
      limit: 5
      rules: [
        collection: Statuses
        field: 'name'
        template: Template.statusPill
        noMatchTemplate: Template.noMatchStatusPill
      ]
    }
