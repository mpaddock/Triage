Template.queuebar.helpers
  queue: ->
    Queues.find().fetch().map (x) ->
      for sg in x.securityGroups
        regex = new RegExp(sg, 'i')
        for group in Meteor.user().memberOf
          if regex.test(group)
            return x.name
  active: ->
    if this.valueOf() is Session.get("queueName")
      return "active"
    else
      return null


