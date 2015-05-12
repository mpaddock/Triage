Template.ticket.helpers
  admin: ->
    _.contains Queues.findOne({name: @queueName})?.memberIds, Meteor.userId()
  author: ->
    Meteor.users.findOne {_id: @authorId}
  ticket: ->
    ticket = Tickets.findOne {ticketNumber: Session.get('ticketNumber')}
    Session.set 'queueName', ticket?.queueName
    return ticket
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
