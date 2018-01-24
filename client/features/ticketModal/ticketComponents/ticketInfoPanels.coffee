Template.ticketInfoPanels.onCreated ->
  @associateUserError = new ReactiveVar ""

Template.ticketInfoPanels.onRendered ->
  doc = @find 'div[name=attachments]'
  doc.ondragover = (e) ->
    @className = 'hover'
    e.preventDefault()
    false


  doc.ondragend = (e) ->
    @className = ''
    e.preventDefault()
    false

  data = @data

  doc.ondrop = (e) ->
    e.preventDefault()
    files = e.dataTransfer.files[0]
    console.log files

    for item in e.dataTransfer.items
      entry = item.webkitGetAsEntry()
      if entry.isFile
        files = e.dataTransfer.files
        for file in files
          FileRegistry.upload file, (fileId) ->
            file = FileRegistry.findOne(fileId)
            console.log 'callback FileRegistry.upload(file,cb)'
            #console.log 'uploaded file', file, ' to ', data
            Tickets.update data._id, {$addToSet: {attachmentIds: fileId}}
            Meteor.call 'setFlag', Meteor.userId(), data._id, 'attachment', true
      else if entry.isDirectory
        traverse = (item, path) ->
          path = path || ''
          if item.isFile
            item.file (file) ->
              FileRegistry.upload file, ->
                console.log 'callback FileRegistry.upload(file,cb)'
          else if item.isDirectory
            item.createReader().readEntries (entries) ->
              traverse entry, path + item.name + '/' for entry in entries
        traverse entry, ''
    false

Template.ticketInfoPanels.helpers
  queueMember: ->
      Meteor.user().isQueueMemberById(@queueId)
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}
  associateUserError: ->
    Template.instance().associateUserError.get()

Template.ticketInfoPanels.events
  'click a[data-action=showAttachmentModal]': (e, tpl) ->
    Iron.query.set 'attachmentId', @valueOf()
  'click a[data-action=removeAttachment]': (e, tpl) ->
    data = { attachmentId: this.valueOf(), ticketId: tpl.data._id }
    Blaze.renderWithData(Template['removeAttachmentModal'], data, $('body').get(0))
    $('#removeAttachmentModal').modal('show')

  'keyup input[name=addTag]': (e, tpl) ->
    if e.which is 13
      val = $(e.target).val()?.split(' ')
      val = _.filter val, (x) -> x.length > 0
      Tickets.update tpl.data._id, { $addToSet: { tags: $each: val } }
      $(e.target).val('')

  'autocompleteselect input[name=addTag]': (e, tpl, doc) ->
    Tickets.update tpl.data._id, { $addToSet: { tags: doc.name } }
    $(e.target).val('')

  'keyup input[name=assignUser]': (e, tpl) ->
    if e.which is 13 and $(e.target).val().length
      id = Meteor.call 'checkUsername', $(e.target).val(), (err, res) ->
        if res
          associateUser tpl, res
          $(e.target).val('')
        else
          tpl.associateUserError.set 'User not found.'
          setTimeout ->
            tpl.associateUserError.set null
          , 3000

  'autocompleteselect input[name=assignUser]': (e, tpl, doc) ->
    associateUser tpl, doc._id
    $(e.target).val('')

  ### Uploading files. ###
  'click a[data-action=uploadFile]': (e, tpl) ->
    Media.pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update tpl.data._id, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), tpl.data._id, 'attachment', true
  'click a[data-action=takePicture]': (e, tpl) ->
    Media.capturePhoto (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update tpl.data._id, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), tpl.data._id, 'attachment', true

associateUser = (tpl, associatedUserId) ->
  queueMember = Meteor.user().isQueueMemberById(tpl.data.queueId)
  associatedQueueMember = Queues.findOne({name: tpl.data.queueName, memberIds: associatedUserId})
  if queueMember or !associatedQueueMember
    #Meteor.call 'associateUserWithTicket', tpl.data._id, associatedUserId
    Tickets.update tpl.data._id, { $addToSet: { associatedUserIds: associatedUserId } }
  else
    tpl.associateUserError.set 'You do not have permission to associate this user.'
    setTimeout ->
      tpl.associateUserError.set null
    , 3000
