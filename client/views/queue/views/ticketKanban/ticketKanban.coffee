limit = Meteor.settings?.public?.limitDefault || 20
offsetIncrement = Meteor.settings?.public?.offsetIncrement || 20

Template.ticketKanban.helpers
  uniqueStatuses: ->
    enableSortable()
    #_.uniq _.pluck Tickets.find().fetch(), 'status'
    Template.instance().statuses.get()
  search: ->
    Iron.query.get('search')? or Iron.query.get('status')? or Iron.query.get('tag')? or Iron.query.get('user')?
  ready: ->
    Session.get 'ready'
  firstVisibleTicket: ->
    if Tickets.find().count() is 0 then 0 else Session.get('offset') + 1
  lastVisibleTicket: ->
    if Session.get('ready')
      Math.min Session.get('offset') + Tickets.find().count(), Counts.get('ticketCount')
    else
      Math.min Session.get('offset') + offsetIncrement, Counts.get('ticketCount')
  lastDisabled: ->
    if Session.get('offset') is 0 then "disabled"
  nextDisabled: ->
    if (Session.get('offset') + offsetIncrement + 1) > Counts.get('ticketCount') then "disabled"
  tickets: ->
    Tickets.find {}, {sort: {submittedTimestamp: -1}}
  ticketsByStatus: (status) ->
    enableSortable()
    Tickets.find { status: status }, { sort: { submittedTimestamp: -1 } }
  noTickets: ->
    Tickets.find().count() is 0
  clientCount: ->
    Tickets.find().count()

Template.ticketKanban.events
  'click button[data-action=setKanban]': (e, tpl) ->
    Session.set 'ticketTemplate', 'ticketKanban'
  'click button[data-action=setTable]': (e, tpl) ->
    Session.set 'ticketTemplate', 'ticketTable'
  'click button[data-action=nextPage]': (e, tpl) ->
    start = Number(Iron.query.get('start')) || 0
    if (start + offsetIncrement) < Counts.get('ticketCount')
      Session.set 'newTicketSet', []
      Iron.query.set 'start', start + offsetIncrement
  'click button[data-action=lastPage]': (e, tpl) ->
    start = Number(Iron.query.get('start')) || 0
    Iron.query.set 'start', Math.max start - offsetIncrement, 0
    Session.set 'newTicketSet', []

  'click a[data-action=clearSearch]': (e, tpl) ->
    e.stopPropagation()
    Iron.query.set 'search', ''
    Iron.query.set 'tag', ''
    Iron.query.set 'status', ''
    Iron.query.set 'user', ''
    Iron.query.set 'start', ''


Template.ticketKanban.onCreated ->
  @statuses = new ReactiveVar []

Template.ticketKanban.onRendered ->
  @autorun =>
    # Clear status set on queue change.
    Session.get 'queueName'
    @statuses.set []
    console.log 'cleared statuses'

  @autorun =>
    # Store statuses in a ReactiveVar so they won't disappear when empty.
    old = @statuses.get()
    statuses = _.pluck Tickets.find().fetch(), 'status'
    union = _.uniq old.concat(statuses)
    if _.difference(union,old).length
      @statuses.set union.sort()

  Meteor.setTimeout ->
    enableSortable()
  , 1000

enableSortable = ->
  $('.status-column-sort-area').sortable({
    connectWith: '.status-column-sort-area'
    handle: '.ticket-card-header'
    stop: (e, ui) ->
      el = ui.item.get(0)
      ticket = Blaze.getData(el)
      status = $(el).closest('.status-column').attr('name')
      Tickets.update ticket._id, { $set: { status: status } }
  })
