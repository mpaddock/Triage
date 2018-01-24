exports.Filter =
  toMongoSelector: (filter) ->
    mongoFilter = {}

    if Array.isArray(filter.queueName)
      mongoFilter.queueName = {$in: filter.queueName}
    else
      mongoFilter.queueName = filter.queueName
    userIds = []

    if Array.isArray(filter.queueId)
        mongoFilter.queueId = { $in: queueId }
    else
        mongoFilter.queueId = filter.queueId

    if filter.user?
      userIds = filter.user.split(',').map (x) ->
        Meteor.users.findOne({username: x})?._id
      userFilter = [
        { authorName: {$in: filter.user.split(',')}},
        { associatedUserIds: {$in: userIds}},
        { authorId: {$in: userIds}}
      ]

    if filter.userId?
      selfFilter = [
          { associatedUserIds: filter.userId },
          { authorId: filter.userId }
      ]

    if Meteor.isServer
      # $text operator doesn't work on the client.
      if filter.search?.trim().length
        if ticketNumber = parseInt(filter.search?.trim())
          mongoFilter['$or'] = [
            { $text:
              { $search: filter.search }
            },
            { ticketNumber: ticketNumber }
          ]
        else
          mongoFilter['$text'] = { $search: filter.search }

    _.each [userFilter, selfFilter], (x) ->
      if x?.length > 0
        unless mongoFilter['$and'] then mongoFilter['$and'] = []
        mongoFilter['$and'].push { $or: x }

    if filter.status?
      if filter.status.charAt(0) is '!'
        status = filter.status.substr(1)
        mongoFilter.status = {$ne: status}
      else
        mongoFilter.status = filter.status || ''

    if filter.tag?
      if filter.tag is "(none)"
        mongoFilter.tags = { $size: 0 }
      else
        tags = filter.tag.split(',')
        sorted = _.sortBy(tags).join(',')
        mongoFilter.tags = {$all: tags}

    if filter.associatedUser?
      if filter.associatedUser is "(none)"
        mongoFilter.associatedUserIds = { $size: 0 }
      else
        users = filter.associatedUser.split(',')
        userIds = _.map users, (u) ->
          Meteor.users.findOne({username: u})?._id
        mongoFilter.associatedUserIds = {$all: userIds}

    return mongoFilter

  verifyFilterObject: (filter, queues, userId) ->
    check filter, Object
    if filter.userId and filter.userId isnt userId
      console.log "Error verifying filter: userId match error"
      return false
    if not filter.queueName
      console.log "Error verifying filter: Queue name is required"
      return false
    if not filter.userId and Array.isArray(filter.queueName) and _.difference(filter.queueName, queues).length isnt 0
      console.log "Error verifying filter: User lacks permission to at least one queue. User has access to #{queues} and requested access to #{filter.queueName}."
      return false
    if not filter.userId and typeof(filter.queueName) is "string" and not _.contains(queues, filter.queueName)
      console.log "Error verifying filter: User lacks permission to a queue. User has access to #{queues} and requested access to #{filter.queueName}."
      return false

    return true
