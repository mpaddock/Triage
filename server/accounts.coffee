Accounts.onLogin (info) ->
  sgs = info.user.memberOf.map (x) ->
    return new RegExp(x.substr(3, x.indexOf(',')-3), "i")
  Queues.find({securityGroups: {$in: sgs}}).forEach (x) ->
    unless x.memberIds?
      x.memberIds = []
    unless info.user._id in x.memberIds
      x.memberIds.push(info.user._id)
      Queues.update x._id, {$set: {memberIds: x.memberIds}}
        
