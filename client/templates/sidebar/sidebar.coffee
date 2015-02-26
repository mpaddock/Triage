Template.sidebar.helpers
  tags: -> Tickets.find().fetch().map (x) ->
    return x.tags
