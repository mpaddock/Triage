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
        }
      ]
    }

Template.sidebar.events
  'keyup input[name=textSearch]': (e, tpl) ->
    if e.keyCode is 13
      text = e.target.value
      filter = Iron.query.get('search')?.split(',') || []
      tags = Iron.query.get('tags')?.split(',') || []
      statuses = Iron.query.get('status')?.split(',') || []

      terms = _.without text.split(' '), "" #Remove trailing spaces.
      terms = _.difference terms, text.match(/status:(\w+|"[^"]*"+|'[^']*')|#\S+/g) #Not the best way of doing this.
      
      newTags = _.union tags, getTags(text)
      newStatus = _.union statuses, getStatuses(text)

      Iron.query.set 'search', terms.join()
      Iron.query.set 'tag', newTags.join()
      Iron.query.set 'status', newStatus.join()
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

