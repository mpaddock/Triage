Template.ticketModal.events
  'click .modal-background, click button[data-dismiss=modal]': (e, tpl) ->
    Iron.query.set 'ticket', null
    Blaze.remove tpl.view

Template.ticketModal.helpers
  ticket: -> Tickets.findOne(@ticketId)
  bodyParagraph: ->
    @body.split('\n')

Template.ticketModal.rendered = ->
  Meteor.call 'removeFlag', Meteor.userId(), @data?.ticketId, 'unread'
