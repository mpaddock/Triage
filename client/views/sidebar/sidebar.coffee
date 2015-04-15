Template.sidebar.helpers
  tags: ->
    _.sortBy Facets.findOne()?.counts.tags, (f) -> -f.count
  status: ->
    _.sortBy Facets.findOne()?.counts.status, (f) -> -f.count

