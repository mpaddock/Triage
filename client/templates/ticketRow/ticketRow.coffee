Template.ticketRow.events
  'keyup input[name=assignUser]': (e, tmpl) ->
    if e.which is 13
      item = this
      id = Meteor.call 'checkUsername', e.target.value, (err, res) ->
        if res
          Session.set "assignError", false
          users = item.associatedUserIds || []
          unless users.indexOf(res) > -1
            users.push (res)
            Tickets.update item._id, {$set: {associatedUserIds: users}}
          $(e.target).val('')
        else
          Session.set "assignError", true

  'click button[data-action=attachFile]': ->
    getMediaFunctions().pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Session.set "currentUploadId", fileId

  'click button[data-action=showAllFields]': ->
    Session.set "allFields", not Session.get "allFields"
  'keyup input[name=newNote]': (e, tmpl) ->
    if e.which is 13
      Changelog.insert
        ticketId: this._id
        timestamp: new Date()
        authorName: Meteor.user().username #Make this name when we publish the profile
        authorId: Meteor.userId()
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), this._id, 'replied', true


      $(e.target).val("")


Template.ticketRow.rendered = ->
  $('[data-toggle=tooltip]').tooltip()
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  notes: -> Changelog.find {ticketId: this._id, type: "note"}
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'replied'})
  allFields: -> Session.get "allFields"
  assignError: -> Session.get "assignError"

getMediaFunctions = () ->
  if Meteor.isCordova
    CordovaMedia
  else
    WebMedia
