Template.ticketModal.helpers
  queues: -> Queues.find()
  errorText: -> Session.get 'errorText'
  submitting: -> Session.get 'submitting'
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

Template.ticketModal.events
  'click button[data-action=submit]': (e, tpl) ->
    Session.set 'submitting', true
    #Probably need a record of 'true' submitter for on behalf of submissions.
    
    #Parsing for tags.
    body = tpl.find('textarea[name=body]').value
    title = tpl.find('input[name=title]').value
    tags = tpl.find('input[name=tags]').value
    splitTags = []
    unless tags is ""
      splitTags = tags.split(',').map (x) ->
        x.replace('#', '')
    hashtags = getTags body
    hashtags = _.uniq hashtags?.concat(getTags(title)).concat(splitTags) || []

    #User tagging.
    users = getUserIds body
    users = _.uniq users?.concat getUserIds(title) || []
    
    #If no onBehalfOf, submitter is the user.
    submitter = tpl.$('input[name=onBehalfOf]').val() || Meteor.user().username
    queueName = tpl.$('select[name=queue]').val()

    Meteor.call 'checkUsername', submitter, (err, res) ->
      if res

        unless submitter is Meteor.user().username
          tpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-error').addClass('has-success')
          tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
          tpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')

        Tickets.insert {
          title: title
          body: body
          tags: hashtags
          associatedUserIds: users
          queueName: queueName
          authorId: res
          authorName: submitter
          status: "Open"
          submittedTimestamp: new Date()
          submissionData:
            method: "Web"
        }, (err, res) ->
          if err
            Session.set 'submitting', false
            Session.set 'errorText', "Error: #{err.message}."
            tpl.$('.has-error').removeClass('has-error')
            for key in err.invalidKeys
              tpl.$('[name='+key.name+']').closest('div .form-group').addClass('has-error')
          else
            clearFields tpl
            $('#ticketModal').modal('hide')
            
      else
        Session.set 'submitting', false
        tpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-success').addClass('has-error')
        tpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
        tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')

  #Username checking and DOM manipulation for on behalf of submission field.
  'click button[data-action=checkUsername]': (e, tpl) ->
    unless tpl.$('input[name="onBehalfOf"]').val() is ""
      Meteor.call 'checkUsername', tpl.$('input[name=onBehalfOf]').val(), (err, res) ->
        if res
          tpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-error').addClass('has-success')
          tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
          tpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')
        else
          tpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-success').addClass('has-error')
          tpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
          tpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')
  
  #When the modal is shown, we get the set of unique tags and update the modal with them.
  'show.bs.modal #ticketModal': (e, tpl) ->
    tpl.$('select[name=queue]').val(Session.get('queueName'))
    tags = _.pluck Tags.find().fetch(), 'name'
    tpl.$('input[name=tags]').select2({
      tags: tags
      tokenSeparators: [' ', ',']
    })

  'click button[data-dismiss="modal"]': (e, tpl) ->
    clearFields tpl
  

Template.ticketModal.rendered = () ->
  tags = _.pluck Tags.find().fetch(), 'name'
  $('input[name=tags]').select2({
    tags: tags
    tokenSeparators: [' ', ',']
  })

clearFields = (tpl) ->
  Session.set 'submitting', false
  Session.set 'errorText', null
  tpl.$('input, textarea').val('')
  tpl.$('.has-error').removeClass('has-error')
  tpl.$('.has-success').removeClass('has-success')
  tpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary').html('Check')
  tpl.$('select[name=queue]').select2('val', '')

