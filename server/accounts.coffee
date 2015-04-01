Accounts.onLogin (info) ->
  usersgs = info.user.memberOf.map (x) ->
    #Pulls the user SG out of the long string given to us by LDAP (after CN=, before ',') and converts to lower case for easier comparison.
    return x.substr(x.indexOf('CN=')+3, x.indexOf(',')-3).toLowerCase()
  Meteor.settings.queues.map (x) ->
    x.securityGroups.forEach (y) ->
      if y.toLowerCase() in usersgs
        queue = Queues.findOne {name: x.name}
        Queues.update queue._id, {$addToSet: {memberIds:info.user._id}}
