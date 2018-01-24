Meteor.methods
  addAdmin: (userId) ->
    if Roles.checkPermissions @userId, 'addAdmin'
      Meteor.users.update(userId, { $set: { applicationRole: Constants.appAdminRole } })

  removeAdmin: (userId) ->
    if Roles.checkPermissions @userId, 'removeAdmin'
      if Meteor.users.findOne({ applicationRole: Constants.appAdminRole }).length > 1
        console.log "#{@userId} updating #{userId}"
        Meteor.users.update userId, { $set:
          {
            applicationRole: Constants.userRole
          }
        }
      else
        throw new Meteor.Error(400, 'There must be at least one application administrator.')

  checkUsername: (username) ->
    if Meteor.settings.ldap.debugMode
        return Meteor.users.findOne({ username: username.toLowerCase() })._id
    # If our user is already in Meteor.users, refresh their information.
    # If not, query LDAP and insert into Meteor.users if a match is found.
    user = Meteor.users.findOne {username: username.toLowerCase()}
    if user?
      Meteor.call 'refreshUserInformation', username.toLowerCase()
      return user._id
    else
      client = LDAP.createClient Meteor.settings.ldap.serverUrl
      LDAP.bind client, Meteor.settings.ldapCredentials.username, Meteor.settings.ldapCredentials.password
      userObj = LDAP.search client, username
      unless userObj?
        return false
      else
        return userId = Meteor.users.insert(userObj)

  refreshUserInformation: (username) ->
    if Meteor.settings.ldap?.debugMode then return
    client = LDAP.createClient Meteor.settings.ldap.serverUrl
    LDAP.bind client, Meteor.settings.ldapCredentials.username, Meteor.settings.ldapCredentials.password
    userObj = LDAP.search client, username
    if userObj
      Meteor.users.update { username: username.toLowerCase() }, { $set: userObj }

