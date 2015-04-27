Template.sidebar.helpers
  tags: ->
    active = Iron.query.get('tag')?.split(',') || []
    _.map _.sortBy(Facets.findOne()?.counts.tags, (f) -> -f.count), (l) ->
      _.extend l,
        checked: if l.name in active then 'checked'
        type: 'tag'
  status: ->
    active = Iron.query.get('status')?.split(',') || []
    _.map _.sortBy(Facets.findOne()?.counts.status, (f) -> -f.count), (l) ->
      _.extend l,
        checked: if l.name in active then 'checked'
        type: 'status'
  search: ->
    Iron.query.get('search')?.split(',')
  settings: ->
    {
      position: "bottom"
      limit: 5
      rules: [
        {
          token: '@'
          collection: Meteor.users
          field: 'username'
          template: Template.userPill
        }
        {
          token: '#'
          collection: Tags
          field: 'name'
          template: Template.tagPill
          noMatchTemplate: Template.noMatchTagPill
        }
      ]
    }

Template.sidebar.events
  'keyup input[name=textSearch]': (e, tpl) ->
    #TODO:Parse for tags n stuff.
    if e.keyCode is 13
      terms = Iron.query.get('search')?.split(',') || []
      unless terms.indexOf(e.target.value) > -1
        terms.push(e.target.value)
      Iron.query.set 'search', terms.join()
      $(e.target).val('')

  'click a[data-action="removeFilter"]': (e, tpl) ->
    e.preventDefault()
    value = this.valueOf()
    filter = Iron.query.get('search')?.split(',') || []
    filter = _.without filter, value
    Iron.query.set 'search', filter.join()

  'change input:checkbox': (e, tpl) ->
    filter = Iron.query.get(@type)?.split(',') || []
    if $(e.target).is(':checked')
      filter.push @name
      filter = _.uniq filter #Just in case something got in there twice.
    else
      filter = _.without filter, @name
    Iron.query.set @type, filter.join()

