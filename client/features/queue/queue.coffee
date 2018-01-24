limit = Meteor.settings?.public?.limitDefault || 20
offsetIncrement = Meteor.settings?.public?.offsetIncrement || 20

Template.queue.events
  'click a[data-action=reconnect]': ->
    Meteor.reconnect()

Template.queue.helpers
  ready: ->
    Session.get 'ready'
  connected: ->
    Meteor.status().connected
  members: ->
    Queues.findOne({name: Session.get('queueName')})?.memberIds
  queueName: ->
    Session.get 'queueName'
  pseudoqueue: ->
    Session.get('pseudoQueue') in ['globalQueue', 'userQueue']
  queues: ->
    Queues.find()
  selected: ->
    if Session.get('pseudoQueue')
      if @name is Meteor.user().defaultQueue then "selected"
    else
      if @_id is Session.get('queueName') then "selected"
  submissionUrl: ->
    Meteor.settings.public.ticketSubmissionUrl
  ticketTemplate: -> 'ticketTable'

Template.queue.rendered = ->
  Session.set 'newTicketSet', []

  @autorun ->
    # Render ticketModal on query parameter change.
    ticketParam = Iron.query.get('ticket')
    if ticketParam
      Meteor.subscribe 'ticket', Number(ticketParam)
      ticket = Tickets.findOne({ ticketNumber: Number(ticketParam) })

    if ticket and not $('.modal-background').length
      Blaze.renderWithData Template.ticketModal, { ticketId: ticket._id }, $('body').get(0)
    else if not ticket
      # In case we navigate with the back button.
      $('#ticket-modal-background').click()

  @autorun ->
    # Render attachment modal on query parameter change.
    attachmentParam = Iron.query.get('attachmentId')
    if attachmentParam and not $('#attachmentModal').length
      Meteor.subscribe 'file', attachmentParam
      file = FileRegistry.findOne(attachmentParam)
      if file
        Blaze.renderWithData Template.attachmentModal, { attachmentId: attachmentParam }, $('body').get(0)
      else
          $('#attachment-modal-background').click()

    else if not attachmentParam
      # Navigating with back button or clearing query param manually should close the modal.
      $('#attachment-modal-background').click()
      

  @autorun ->
    # When queueName changes, reset the new set of tickets to an empty array.
    Session.get('queueName')
    Session.set 'newTicketSet', []

  @autorun ->
    # Highlighting of search terms.
    if Iron.query.get('search') and Session.get('ready')
      Meteor.setTimeout ->
        $('td').unhighlight()
        $('td').highlight(Iron.query.get('search')?.split(','))
      , 500

  @autorun ->
    renderedTime = new Date()
    queueName = Session.get('queueName') || _.pluck Queues.find().fetch(), '_id'
    filter = {
      queueName: queueName
      search: Iron.query.get 'search'
      status: Iron.query.get 'status'
      tag: Iron.query.get 'tag'
      user: Iron.query.get 'user'
      associatedUser: Iron.query.get 'associatedUser'
    }
    if Session.get('pseudoQueue') is 'userQueue'
      filter.userId = Meteor.userId()
    
    mongoFilter = Filter.toMongoSelector filter
    _.extend mongoFilter, {submittedTimestamp: {$gt: renderedTime}}
    Tickets.find(mongoFilter).observe
      added: (ticket) ->
        if Session.get('offset') < 1
          Session.set 'newTicketSet', (_.uniq(Session.get('newTicketSet')?.concat(ticket._id)) || [ticket._id])
    Meteor.subscribe 'ticketSet', Session.get 'newTicketSet'
