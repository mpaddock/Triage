Template.sidebar.helpers
  tags: ->
    #sloppy
    tags = Tickets.find({queueName: Session.get("queueName")}).fetch().map (x) ->
      return x.tags
    flattened = []
    return _.uniq flattened.concat.apply(flattened, tags).filter (n) ->
      return n != undefined
  status: -> _.uniq Tickets.find({queueName: Session.get("queueName")}).fetch().map (x) ->
      return x.status
