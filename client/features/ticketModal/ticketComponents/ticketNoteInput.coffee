Template.ticketNoteInput.helpers
  allowStatusChange: ->
    if Tickets.findOne(@ticketId).status isnt "Closed"
      return true
    else
      sinceClose = (Date.now() - Tickets.findOne(@ticketId).closedTimestamp)/1000
      max = Meteor.settings?.public?.reopenAllowedTimespan
      return sinceClose < max
  closed: -> Tickets.findOne(@ticketId).status is "Closed"
  beta: -> Meteor.settings.public.beta
  status: -> Tickets.findOne(@ticketId).status
  statusSettings: ->
    {
      position: "bottom"
      limit: 5
      rules: [
        collection: Tags 
        field: 'name'
        template: Template.statusPill
        noMatchTemplate: Template.noMatchStatusPill
      ]
    }

Template.ticketNoteInput.events
  'click button[name=addNote]': (e, tpl) ->
    addNote e, tpl, false, false

  'click button[name=addNoteAdmin]': (e, tpl) ->
    addNote e, tpl, true, false

  'click button[name=addInternalNote]': (e, tpl) ->
    addNote e, tpl, true, true

  'click button[name=addNoteAndReOpen]': (e, tpl) ->
    if tpl.$('textarea[name=newNote]').val().trim().length > 0
      addNote e, tpl, true, false
    Tickets.update tpl.data.ticketId, { $set: {status: 'Open'} }

  'click button[name=addNoteAndClose]': (e, tpl) ->
    if tpl.$('textarea[name=newNote]').val().trim().length > 0
      addNote e, tpl, true, false
    Tickets.update tpl.data.ticketId, { $set: {status: 'Closed'} }

  'click button[name=closeSilently]': (e, tpl) ->
    Meteor.call 'closeSilently', tpl.data.ticketId

  'input textarea[name=newNote]': (e, tpl) ->
    if $(e.target).val() is ""
      tpl.$('button[name=addNoteAndReOpen]').text("Re-Open Ticket")
      tpl.$('button[name=addNoteAndClose]').text("Close Ticket")
    else
      tpl.$('button[name=addNoteAndReOpen]').text('Add Note and Re-Open')
      tpl.$('button[name=addNoteAndClose]').text('Add Note and Close')

  'click .dropdown-menu[name=statusMenu]': (e, tpl) ->
    e.stopPropagation()

  'click .dropdown-menu[name=statusMenu] a': (e, tpl) ->
    ticket = Tickets.findOne(@ticketId)
    unless ticket.status is $(e.target).html()
      Tickets.update @ticketId, {$set: {status: $(e.target).html()}}
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
  
  'autocompleteselect input[name=customStatus]': (e, tpl, doc) ->
    Tickets.update tpl.data.ticketId, { $set: { status: doc.name } }
    $(e.target).val("")
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')

  'keyup input[name=customStatus]': (e, tpl) ->
    if e.which is 13
      Tickets.update tpl.data.ticketId, { $set: { status: $(e.target).val() } }
      $(e.target).val("")
      tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')


  ### Uploading files. ###
  'click a[data-action=uploadFile]': (e, tpl) ->
    Media.pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update @ticketId, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), @ticketId, 'attachment', true

 
addNote = (e, tpl, admin, internal) ->
  # Adds notes given the event and template.
  # Admin flag will result in parsing for status.
  # Other notes will be parsed for tags and associated users.
  # Internal flag will add an internal note.
  unless admin then internal = false
  ticket = Tickets.findOne(tpl.data.ticketId)
  body = tpl.$('textarea[name=newNote]').val()
  hashtags = Parsers.getTags body
  users = Parsers.getUserIds body

  if users?.length > 0
    unless admin
      users = _.filter users, (u) ->
        !Queues.findOne({name: ticket.queueName, memberIds: u})?
    Tickets.update tpl.data.ticketId, {$addToSet: {associatedUserIds: $each: users}}

  if hashtags?.length > 0
    Tickets.update tpl.data.ticketId, {$addToSet: {tags: $each: hashtags}}

  if admin
    status = Parsers.getStatuses body
    if status?.length > 0
      Tickets.update tpl.data.ticketId, {$set: {status: status[0]}} #If multiple results, just use the first.

  if body
    Changelog.insert
      ticketId: tpl.data.ticketId
      timestamp: new Date()
      authorId: Meteor.userId()
      authorName: Meteor.user().username
      internal: internal
      type: "note"
      message: body

  Meteor.call 'setFlag', Meteor.userId(), tpl.data.ticketId, 'replied', true

  tpl.$('textarea[name=newNote]').val('')

  tpl.$('button[name=addNoteAndReOpen]').text("Re-Open Ticket")
  tpl.$('button[name=addNoteAndClose]').text("Close Ticket")
