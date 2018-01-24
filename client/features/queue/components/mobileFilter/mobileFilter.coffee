Template.mobileFilter.helpers
  closed: ->
    {
      name: "Closed"
      type: "status"
      count: Tickets.find({status: "Closed"}).count()
    }
  tags: ->
    active = Iron.query.get('tag')?.split(',') || []
    _.map _.sortBy(Facets.findOne()?.facets.tags, (f) -> -f.count), (l) ->
      if _.isNull(l.name) then l.name = '(none)'
      _.extend l,
        checked: if l.name in active then 'checked'
        type: 'tag'
  zeroCountTags: ->
    active = Iron.query.get('tag')?.split(',') || []
    tags = _.pluck Facets.findOne()?.facets.tags, 'name'
    if '(none)' in active and Tickets.findOne()
      tags.push('(none)')
    return _.map _.difference(active, tags), (l) ->
      name: l
      count: 0
      checked: if l in active then "checked"
      type: 'tag'
  status: ->
    active = Iron.query.get('status')?.split(',') || []
    _.map _.sortBy(Facets.findOne()?.facets.status, (f) -> -f.count), (l) ->
      _.extend l,
        checked: if l.name in active then 'checked'
        type: 'status'
  zeroCountStatus: ->
    active = Iron.query.get('status')?.split(',') || []
    status = _.pluck Facets.findOne()?.facets.status, 'name'
    return _.map _.difference(active, status), (l) ->
      name: l
      count: 0
      checked: if l in active then 'checked'
      type: 'status'
  associatedUsers: ->
    active = Iron.query.get('associatedUser')?.split(',') || []
    _.map _.sortBy(Facets.findOne()?.facets.associatedUserIds, (f) -> -f.count), (l) ->
      unless _.isNull(l.name)
        username = Meteor.users.findOne(l.name)?.username
        _.extend l,
          username: username
          checked: if username in active then 'checked'
          type: 'associatedUser'
      else
        _.extend l,
          username: '(none)'
          checked: if '(none)' in active then 'checked'
          type: 'associatedUser'

  zeroCountUsers: ->
    active = Iron.query.get('associatedUser')?.split(',') || []
    users = _.pluck Facets.findOne()?.facets.associatedUserIds, 'name'
    usernames = _.map users, (u) ->
      Meteor.users.findOne(u)?.username
    if '(none)' in active and Tickets.findOne()
      usernames.push('(none)')
    return _.map _.difference(active, usernames), (l) ->
      username: l
      count: 0
      checked: if l in active then 'checked'
      type: 'associatedUser'
    
  textFilter: ->
    Iron.Location.get().queryObject?.search?.split(',')
  userFilter: ->
    Iron.Location.get().queryObject?.user?.split(',')
  filtering: ->
    ( Iron.query.get('status')? or Iron.query.get('tag')? or (Session.get('ready') is false) ) and ( Session.get('queueName')? or Session.get('pseudoQueue') )

Template.mobileFilter.events
  'hide.bs.collapse': (e, tpl) ->
    tpl.$('span[name='+e.target.id+']').removeClass('glyphicon-chevron-up').addClass('glyphicon-chevron-down')

  'show.bs.collapse': (e, tpl) ->
    tpl.$('span[name='+e.target.id+']').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-up')

  'keyup input[name=textSearch], click button[name=textSearch]': (e, tpl) ->
    if (e.type is 'click' or e.keyCode is 13) and tpl.$('input[name=textSearch]').val().trim() isnt ""
      text = tpl.$('input[name=textSearch]').val()
      filter = Iron.query.get('search')?.split(',') || []
      tags = Iron.query.get('tags')?.split(',') || []
      statuses = Iron.query.get('status')?.split(',') || []
      users = Iron.query.get('user')?.split(',') || []
      terms = Parsers.getTerms text
      _.map terms, (t) ->
        t.replace('"', '\"')
      newFilter = _.union terms, filter
      newTags = _.union tags, Parsers.getTags(text)
      newStatus = _.union statuses, Parsers.getStatuses(text)
      newUsers = _.union users, Parsers.getUsernames(text)

      Iron.query.set 'search', newFilter.join()
      Iron.query.set 'tag', newTags.join()
      Iron.query.set 'status', newStatus.join()
      Iron.query.set 'user', newUsers.join()
      Iron.query.set 'start', 0
      tpl.$('input[name=textSearch]').val('')
      Session.set 'newTicketSet', []

  'click a[data-action="removeFilter"]': (e, tpl) ->
    e.preventDefault()
    type = $(e.target).closest('a').data('type')
    filter = Iron.query.get(type)?.split(',') || []
    value = this.valueOf()
    filter = _.without filter, value
    Iron.query.set type, filter.join()
    Iron.query.set 'start', 0
  
  'change input:checkbox': (e, tpl) ->
    filter = Iron.query.get(@type)?.split(',') || []
    if @type is 'associatedUser' then name = @username else name = @name
    if $(e.target).is(':checked')
      filter.push name
      filter = _.uniq filter #Just in case something got in there twice.
    else
      filter = _.without filter, name
    Iron.query.set @type, filter.join()
    Iron.query.set 'start', 0

