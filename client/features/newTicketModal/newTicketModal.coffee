Template.newTicketModal.helpers
  queues: -> Queues.find()
  errorText: -> Template.instance().errorText.get()
  submitting: -> Template.instance().submitting.get()
  files: ->
    files = Template.instance().attachedFiles.get()
    if files.length
      FileRegistry.find { _id: { $in: files } }

Template.newTicketModal.events
  'click .modal-background, click button[data-dismiss=modal]': (e, tpl) ->
    tpl.$('input[name=tags]').select2('destroy') # Removes a DOM artifact select2 leaves
    Blaze.remove tpl.view

  'click button[data-action=uploadFile]': (e, tpl) ->
    Media.pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      files = tpl.attachedFiles.get() || []
      files.push(fileId)
      tpl.attachedFiles.set files

  'click a[data-action=removeAttachment]': (e, tpl) ->
    id = $(e.target).data('file')
    tpl.attachedFiles.set(_.without(tpl.attachedFiles.get(), id))

  'click button[data-action=submit]': (e, tpl) ->
    tpl.submitting.set true

    #Parsing for tags.
    body = tpl.find('textarea[name=body]').value
    title = tpl.find('input[name=title]').value
    tags = tpl.find('input[name=tags]').value
    splitTags = []
    unless tags is ""
      splitTags = tags.split(',').map (x) ->
        x.replace('#', '')
    hashtags = Parsers.getTags body
    hashtags = _.uniq hashtags?.concat(Parsers.getTags(title)).concat(splitTags) || []

    #User tagging.
    users = Parsers.getUserIds body
    users = _.uniq users?.concat Parsers.getUserIds(title) || []
    
    #If no onBehalfOf, submitter is the user.
    submitter = tpl.$('input[name=onBehalfOf]').val() || Meteor.user().username
    queueId = tpl.$('select[name=queue]').val()
    queueName = tpl.$('select[name=queue]').data('queueName')

    Meteor.call 'checkUsername', submitter, (err, res) ->
      if res
        unless submitter is Meteor.user().username
          setUsernameSuccess tpl

        ticket = {
            title: title
            body: body
            tags: hashtags
            associatedUserIds: users
            queueId: queueId
            queueName: queueName,
            authorId: res
            authorName: submitter
            status: 'Open'
            submittedTimestamp: new Date()
            attachmentIds: tpl.attachedFiles.get()
            submissionData:
                method: "Web"
        }

        Meteor.call 'createTicket', ticket, (err, res) ->
          if err
            tpl.submitting.set false
            tpl.errorText.set "Error: #{err.message}."
            tpl.$('.has-error').removeClass('has-error')
            console.log err
            for key in err.invalidKeys
              tpl.$('[name='+key.name+']').closest('div .form-group').addClass('has-error')
          else
            clearFields tpl
            $('.modal-background').click()
            
      else
        tpl.submitting.set false
        setUsernameFail tpl

  #Username checking and DOM manipulation for on behalf of submission field.
  'click button[data-action=checkUsername]': (e, tpl) ->
    checkUsername e, tpl, tpl.$('input[name="onBehalfOf"]').val()

  'keyup input[name=onBehalfOf]': (e, tpl) ->
    if e.which is 13
      checkUsername e, tpl, tpl.$('input[name="onBehalfOf"]').val()

  'autocompleteselect input[name=onBehalfOf]': (e, tpl) ->
    setUsernameSuccess tpl

  # When the modal is shown, we get the set of unique tags and update the modal with them.
  # Could do this with mizzao:autocomplete now...
  'show.bs.modal #newTicketModal': (e, tpl) ->
    tpl.$('select[name=queue]').val(Session.get('queueName'))
    tags = _.pluck Tags.find().fetch(), 'name'
    tpl.$('input[name=tags]').select2({
      tags: tags
      tokenSeparators: [' ', ',']
    })

  'click button[data-dismiss="modal"]': (e, tpl) ->
    clearFields tpl
  
Template.newTicketModal.onCreated ->
  @attachedFiles = new ReactiveVar([])
  @errorText = new ReactiveVar()
  @submitting = new ReactiveVar(false)

Template.newTicketModal.onRendered () ->
  tpl = @
  @autorun ->
    if tpl.attachedFiles.get().length
      Meteor.subscribe 'unattachedFiles', tpl.attachedFiles.get()

  tags = _.pluck Tags.find().fetch(), 'name'
  $('input[name=tags]').select2({
    tags: tags
    tokenSeparators: [' ', ',']
  })

clearFields = (tpl) ->
  tpl.submitting.set false
  tpl.errorText.set null
  tpl.attachedFiles.set []
  tpl.$('input, textarea').val('')
  tpl.$('.has-error').removeClass('has-error')
  tpl.$('.has-success').removeClass('has-success')
  tpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary').html('Check')


checkUsername = (e, tpl, val) ->
  if val.length
    Meteor.call 'checkUsername', val, (err, res) ->
      if res
        setUsernameSuccess tpl
      else
        setUsernameFail tpl

setUsernameSuccess = (tpl) ->
  tpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-error').addClass('has-success')
  tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
  tpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')

setUsernameFail = (tpl) ->
  tpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-success').addClass('has-error')
  tpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
  tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')
