Handlebars.registerHelper 'arrayify', (obj) ->
  result = []
  for k,v of obj
    result.push {
      name: k
      value: v
    }
  return result
