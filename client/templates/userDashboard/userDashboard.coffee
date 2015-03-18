Template.userDashboard.helpers
  queue: ->
    #Intense. We iterate over the securitygroups allowed by the queue, and then iterate over the lines in Meteor.user().memberOf to test if the SGs are in the lines. This is certainly sub-optimal.
    Queues.find().fetch().map (x) ->
      for sg in x.securityGroups
        regex = new RegExp(sg, 'i')
        for group in Meteor.user().memberOf
          if regex.test(group)
            return x.name
        
        
