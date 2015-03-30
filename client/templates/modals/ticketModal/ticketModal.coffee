Template.ticketModal.helpers
  queues: -> Queues.find()

Template.ticketModal.events
  'click button[data-action=submit]': (e, tmpl) ->
    #Probably need a record of 'true' submitter for on behalf of submissions.
    
    #Parsing for tags.
    body = tmpl.find('textarea[name=body]').value
    title = tmpl.find('input[name=title]').value
    hashtags = getTags body
    hashtags = hashtags?.concat getTags(title) || []
    hashtags = hashtags?.filter unique

    #User tagging.
    users = getUsers body
    users = users?.concat getUsers(title) || []
    users = users.filter unique
    
    #If no onBehalfOf, submitter is the user.
    submitter = tmpl.find('input[name=onBehalfOf]').value || Meteor.user().username

    queueNames = _.pluck tmpl.findAll('input[name=queueName]:checked'), "value"
    if queueNames.length is 0
      #Simpleschema validation will pass with an empty array for queueNames...
      queueNames = null

    Meteor.call 'checkUsername', submitter, (err, res) ->
      if res

        unless submitter is Meteor.user().username
          tmpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-error').addClass('has-success')
          tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
          tmpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')

        id = Tickets.insert {
          title: title
          body: body
          tags: hashtags
          associatedUserIds: users
          queueName: queueNames
          authorId: res
          authorName: submitter
          status: "open"
          submittedTimestamp: new Date()
          submissionData:
            method: "Web"
        }, (err, res) ->
          if err
            tmpl.$('.has-error').removeClass('has-error')
            for key in err.invalidKeys
              tmpl.$('[name='+key.name+']').closest('div .form-group').addClass('has-error')
          else
            $('#ticketModal').modal('hide')
            
      else
        tmpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-success').addClass('has-error')
        tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
        tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')

  'click button[data-action=checkUsername]': (e, tmpl) ->
    #Username checking and DOM manipulation for on behalf of submission field.
    unless tmpl.$('input[name="onBehalfOf"]').val() is ""
      Meteor.call 'checkUsername', tmpl.$('input[name=onBehalfOf]').val(), (err, res) ->
        if res
          tmpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-error').addClass('has-success')
          tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
          tmpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')
        else
          tmpl.$('input[name=onBehalfOf]').closest('div .form-group').removeClass('has-success').addClass('has-error')
          tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
          tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')
  
  'hidden.bs.modal #ticketModal': (e, tmpl) ->
    tmpl.$('input[name=title]').val('')
    tmpl.$('textarea[name=body]').val('')
    tmpl.$('.has-error').removeClass('has-error')
    tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary').html('Check')
    tmpl.$('input[name=queueName]').attr('checked', false)
