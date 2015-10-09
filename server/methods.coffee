Meteor.methods
  checkUsername: (username) ->
    #If our user is already in Meteor.users, cool. If not, query LDAP and insert into Meteor.users.
    user = Meteor.users.findOne {username: username.toLowerCase()}
    if user?
      return user._id
    else
      client = LDAP.createClient Meteor.settings.ldap.serverUrl
      LDAP.bind client, Meteor.settings.ldapDummy.username, Meteor.settings.ldapDummy.password
      userObj = LDAP.search client, username
      unless userObj?
        return false
      else
        user = Meteor.users.findOne {username: username.toLowerCase()}
        if user
          userId = user._id
          Meteor.users.update(userId, {$set: userObj})
        else
          userId = Meteor.users.insert(userObj)
        return userId

  refreshSecurityGroups: (username) ->
    client = LDAP.createClient Meteor.settings.ldap.serverUrl
    LDAP.bind client, Meteor.settings.ldapDummy.username, Meteor.settings.ldapDummy.password
    userObj = LDAP.search client, username
    if userObj
      Meteor.users.update { username: username.toLowerCase() }, { $set: { memberOf: userObj.memberOf } }

  closeSilently: (ticketId) ->
    ticket = Tickets.findOne(ticketId)
    if Queues.findOne { name: ticket.queueName, memberIds: @userId }
      d = new Date()
      Tickets.direct.update ticketId, { $set: {
        status: 'Closed'
        timeToClose: (d - ticket.submittedTimestamp) / 1000 # Amount of time to ticket close, in seconds.
        closedTimestamp: d
        closedByUserId: @userId
        closedByUsername: Meteor.users.findOne(@userId).username
      } }

      Changelog.direct.insert
        ticketId: ticketId
        timestamp: new Date()
        authorId: @userId
        authorName: Meteor.users.findOne(@userId)?.username
        type: 'field'
        field: 'status'
        oldValue: ticket.status
        newValue: 'Closed'
