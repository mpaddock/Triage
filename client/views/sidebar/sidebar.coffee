Template.sidebar.helpers
  tags: ->
    _.sortBy Facets.findOne()?.counts.tags, (f) -> -f.count
  status: ->
    _.sortBy Facets.findOne()?.counts.status, (f) -> -f.count
  search: ->
    Iron.query.get('search')?.split(',')
  checkedTag: ->
    #Can we combine these two?
    filters = Iron.query.get('tag')?.split(',') || []
    if this.name in filters
      return 'checked'
  checkedStatus: ->
    filters = Iron.query.get('status')?.split(',') || []
    if this.name in filters
      return 'checked'

Template.sidebar.events
  'keyup input[name=textSearch]': (e, tpl) ->
    #TODO:Parse for tags n stuff.
    if e.keyCode is 13
      terms = Iron.query.get('search')?.split(',') || []
      unless terms.indexOf(e.target.value) > -1
        terms.push(e.target.value)
      Iron.query.set 'search', terms.join()
      $(e.target).val('')

  'change input:checkbox': (e, tpl) ->
    type = e.target.name #Type of filter we're setting.
    filter = Iron.query.get(type)?.split(',') || []
    if $(e.target).is(':checked')
      filter.push $(e.target).data(type)
      filter = _.uniq filter #Just in case something got in there twice.
    else
      filter = _.without filter, $(e.target).data(type)
    Iron.query.set type, filter.join()

  'click a[data-action="removeFilter"]': (e, tpl) ->
    e.preventDefault()
    value = this.valueOf()
    filter = Iron.query.get('search')?.split(',') || []
    filter = _.without filter, value
    Iron.query.set 'search', filter.join()
