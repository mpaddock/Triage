@Filter =
  toMongoSelector: (filter) ->
    mongoFilter = {}
    if Array.isArray(filter.queueName)
      mongoFilter.queueName = {$in: filter.queueName}
    else
      mongoFilter.queueName = filter.queueName
    userIds = []
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
          { authorId: filter.userId },
          { submittedByUserId: filter.userId }
      ]
    if Meteor.isServer
      # $text operator doesn't work on the client.
      if filter.search?.trim().length
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
      tags = filter.tag.split(',')
      sorted = _.sortBy(tags).join(',')
      mongoFilter.tags = {$all: tags}
    if filter.associatedUser?
      users = filter.associatedUser.split(',')
      userIds = _.map users, (u) ->
        Meteor.users.findOne({username: u})?._id
      mongoFilter.associatedUserIds = {$all: userIds}
    return mongoFilter

  toFacetString: (filter) ->
    check filter, Object
    if typeof filter.queueName is 'string'
      facetPath = "queueName:#{filter.queueName}"
    else
      facetPath = "queueName:#{filter.queueName?.join(',')}"
    if filter.search?.trim().length
      facetPath += "|search:#{filter.search}"
    if filter.status?.trim().length
      facetPath += "|status:#{filter.status}"
    if filter.tag?.length
      sortedTags = _.sortBy(filter.tag.split(',')).join(',')
      facetPath += "|tags:#{sortedTags}"
    if filter.userId?
      facetPath += "|user:#{filter.userId}"
    return facetPath

  fromFacetString: (facetString) ->
    check facetString, String
    filter =
      queueName: ''
      search: ''
      status: ''
      tags: []
      userId: ''
    for f in facetString.split('|')
      f = f.split(':')
      if f[0] is 'tags' or f[0] is 'queueName'
        filter[f[0]] = f[1].split(',')
      else
        filter[f[0]] = f[1]
    return filter
 
  verifyFilterObject: (filter, queues, userId) ->
    check filter, Object
    if filter.userId and filter.userId isnt userId
      console.log "Error verifying filter: userId match error"
      return false
    if not filter.queueName
      console.log "Error verifying filter: Queue name is required"
      return false
    if not filter.userId and Array.isArray(filter.queueName) and _.difference(filter.queueName, queues).length isnt 0
      console.log "Error verifying filter: User lacks permission to at least one queue"
      return false
    if not filter.userId and typeof(filter.queueName) is "string" and not _.contains(queues, filter.queueName)
      console.log "Error verifying filter: User lacks permission to a queue"
      return false

    return true

if Meteor.isServer
  Facets.configure Tickets,
    tags: [String]
    status: String
    associatedUserIds: [String]

