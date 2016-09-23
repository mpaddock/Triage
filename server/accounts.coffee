Accounts.onLogin (info) ->
  Meteor.call 'refreshUserInformation', info.user.username
  usersgs = info.user.memberOf.map (x) ->
    #Pulls the user SG out of the long string given to us by LDAP (after CN=, before ',') and converts to lower case for easier comparison.
    return x.substr(x.indexOf('CN=')+3, x.indexOf(',')-3).toLowerCase()
  Meteor.settings.queues.map (queue) ->
    member = false
    queue.securityGroups.forEach (sg) ->
      if sg.toLowerCase() in usersgs
        queue = Queues.findOne { name: queue.name }
        Queues.update queue._id, { $addToSet: { memberIds:info.user._id } }
        member = true
      else if Queues.findOne({ name: queue.name, memberIds: info.user._id }) and not member
        queue = Queues.findOne({ name: queue.name })
        Queues.update queue._id, { $pull: { memberIds: info.user._id } }

    #Make sure there's an entry for badge counts for each queue the user has access to.
    Queues.find({memberIds: info.user._id}, {fields: {'name': 1}}).forEach (q) ->
      if not QueueBadgeCounts.findOne({ userId: info.user._id, queueName: q.name})
        QueueBadgeCounts.insert { userId: info.user._id, queueName: q.name, count: 0 }
