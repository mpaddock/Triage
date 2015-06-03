Template.ticket.helpers
  admin: ->
    _.contains Queues.findOne({name: @queueName})?.memberIds, Meteor.userId()
  ticket: ->
    ticket = Tickets.findOne {ticketNumber: Session.get('ticketNumber')}
    Session.set 'queueName', ticket?.queueName
    return ticket
  bodyParagraph: ->
    @body.split('\n')
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
