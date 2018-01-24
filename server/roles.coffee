@Roles = {}

@Roles[Constants.appAdminRole] = [
    'allQueues'
    'addAdmin'
    'removeAdmin'
    'activateQueue'
    'deactivateQueue'
    'removeQueue'
    'addQueue'
]

@Roles.checkPermissions = (userId, method) ->
    role = Meteor.users.findOne(userId).applicationRole
    return method in Roles[role]
