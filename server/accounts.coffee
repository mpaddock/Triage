Accounts.onLogin (info) ->
    # Our first user is the application admin. Congrats, first user.
    if Meteor.users.find().count() is 1
        Meteor.users.update info.user?._id, { $set: { applicationRole: Constants.appAdminRole } }
    
    # Make sure app admins are listed as members and admins of all queues, avoiding role-specific logic for queues
    if Meteor.users.findOne(info.user?._id).isAppAdmin()
        Queues.update {}, { $addToSet: { memberIds: info.user._id, adminIds: info.user._id } }, { multi: true }

