Meteor.methods
  deactivateQueue: (queueId) ->
    if Roles.checkPermissions @userId, 'deactivateQueue'
      Queues.update queueId, { $set: { active: false } }

  activateQueue: (queueId) ->
    if Roles.checkPermissions @userId, 'activateQueue'
      Queues.update queueId, { $set: { active: true } }

  addQueue: (queueName) ->
    if Roles.checkPermissions @userId, 'addQueue'
      Queues.insert {
        name: queueName,
        securityGroups: []
      }

  deleteQueue: (queueId) ->
    # Remove the queue, but leave data relying on it
    if Roles.checkPermissions @userId, 'activateQueue'
      Queues.remove queueId
