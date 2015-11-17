Template.ticket.helpers
  ticket: ->
    ticket = Tickets.findOne {ticketNumber: Session.get('ticketNumber')}
    Session.set 'queueName', ticket?.queueName
    return ticket
  bodyParagraph: ->
    @body.split('\n')

Template.ticket.rendered = () ->
  if Tickets.findOne()
    Meteor.call 'removeFlag', Meteor.userId(), Tickets.findOne()._id, 'unread'
