Template.ticketRow.events
  ### Events for ticket status changes. ###
  'click .dropdown-menu': (e, tmpl) ->
    #Needed to stop wacky table row expansion. We have to toggle the dropdown manually as a result in our events.
    e.stopPropagation()
  'click .dropdown-menu a': (e, tmpl) ->
    Meteor.call 'updateStatus', Meteor.userId(), this._id, $(e.target).html()
    tmpl.$('.dropdown-toggle').dropdown('toggle')

  
  'keyup input[name=customStatus]': (e, tmpl) ->
    if e.which is 13
      Meteor.call 'updateStatus', Meteor.userId(), this._id, e.target.value
      $(e.target).val("")
      tmpl.$('.dropdown-toggle').dropdown('toggle')
    
  ### Assigning users to tickets. ###
  'keyup input[name=assignUser]': (e, tmpl) ->
    if e.which is 13
      item = this
      id = Meteor.call 'checkUsername', e.target.value, (err, res) ->
        if res
          tmpl.$('[data-toggle="tooltip"]').tooltip('hide')
          Session.set "assignError", false
          users = item.associatedUserIds || []
          unless users.indexOf(res) > -1
            users.push (res)
            Tickets.update item._id, {$set: {associatedUserIds: users}}
          $(e.target).val('')
        else
          tmpl.$('[data-toggle="tooltip"]').tooltip('show')

  'click button[data-action=attachFile]': ->
    getMediaFunctions().pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Session.set "currentUploadId", fileId

  'click button[data-action=showAllFields]': ->
    Session.set "allFields", not Session.get "allFields"
  ### Adding notes to tickets. ###
  'keyup input[name=newNote]': (e, tmpl) ->
    if e.which is 13
      Changelog.insert
        ticketId: this._id
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), this._id, 'replied', true

      $(e.target).val("")
  # Hide all tooltips on row collapse and focusout of assign user field. 
  'hidden.bs.collapse': (e, tmpl) ->
    tmpl.$('[data-toggle="tooltip"]').tooltip('hide')
    tmpl.$('input[name="assignUser"]').val('')

  'focusout input[name="assignUser"]': (e, tmpl) ->
    tmpl.$('[data-toggle="tooltip"]').tooltip('hide')


Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  notes: -> Changelog.find {ticketId: this._id, type: "note"}
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'replied'})
  allFields: -> Session.get "allFields"

getMediaFunctions = () ->
  if Meteor.isCordova
    CordovaMedia
  else
    WebMedia
