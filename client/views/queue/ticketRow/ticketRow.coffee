Template.ticketRow.events
  'click .ticket-row': (e) ->
    Meteor.call 'removeFlag', Meteor.userId(), @_id, 'unread'
    Blaze.renderWithData Template.ticketModal, @, $('body').get(0)
    $('#ticketModal').modal('show')

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
    Counts.get("#{@_id}-noteCount") || null
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
