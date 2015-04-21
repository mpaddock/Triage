Template.queuebar.helpers
  queue: -> Queues.find {memberIds: Meteor.userId()} #Only show queues in queuebar that the user is a member of. No tickets are published for queues they're not a member of.
  active: ->
    if this.name is Session.get("queueName")
      return "active"
    else
      return null


