Template.queuebar.helpers
  queue: -> Queues.find()
  active: ->
    if this.name is Session.get("queueName")
      return "active"
    else
      return null


