Template.processMiner.onCreated ->
  @subscribe 'processMiner'

Template.processMiner.helpers
  changes: ->
    changes = _.countBy Changelog.find().fetch(), (c) -> JSON.stringify _.pick c, 'oldValue', 'newValue'
    changes = _.map changes, (v, k) ->
      _.extend JSON.parse(k), count: v
    changes = _.sortBy changes, (c) -> -c.count
  graph: ->
    nodes = Changelog.find({},{fields: {oldValue: 1}}).map (d) -> d.oldValue
    nodes = nodes.concat Changelog.find({},{fields: {newValue: 1}}).map (d) -> d.newValue
    nodes = _.unique nodes
    nodes = _.map nodes, (n,i) -> {status: n, x: 0.5*3*160+0.5*3*90*Math.cos(2*Math.PI*i/nodes.length), y: 3*90-0.5*3*90*Math.sin(2*Math.PI*i/nodes.length)}

    edges = _.countBy Changelog.find().fetch(), (c) ->
      JSON.stringify _.pick c, 'oldValue', 'newValue'
    edges = _.map edges, (count, k) ->
      j = JSON.parse(k)
      from = _.find nodes, (n) -> n.status == j.oldValue
      to = _.find nodes, (n) -> n.status == j.newValue
      {from: from, to: to, count: 0.1*count}

    {nodes: nodes, edges: edges}

