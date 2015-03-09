Template.queuebar.helpers
  queue: -> Queues.find {$or: [{members: Meteor.user().username}, {admins: Meteor.user().username}]}
  active: ->
    if this.name is Session.get("queueName")
      return "active"
    else
      return null


