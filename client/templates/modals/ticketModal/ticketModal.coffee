unique = (value, index, self) ->
  #filter function for unique arrays.
  self.indexOf(value) is index

Template.ticketModal.events
  'hidden.bs.modal #ticketModal': (e, tmpl) ->
    tmpl.$('input[name=title]').val('')
    tmpl.$('textarea[name=body]').val('')
    tmpl.$('.has-error').removeClass('has-error')
    tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary').html('Check')
    tmpl.$('input[name=queueName]').attr('checked', false)
 
  'click button[data-action=submit]': (e, tmpl) ->
    #Probably need a record of 'true' submitter for on behalf of submissions.
    
    #Parsing for tags.
    body = tmpl.find('textarea[name=body]').value
    title = tmpl.find('input[name=title]').value
    hashtags = body.match(/#\S+/g) || []
    hashtags = hashtags.concat(title.match(/#\S+/g) || [])
    hashtags = hashtags.filter unique

    #User tagging.
    usertags = body.match(/\@\S+/g) || []
    usertags = usertags.concat(title.match(/\@\S+/g) || [])
    usertags = usertags.filter unique
    users = []
    
    _.each usertags, (username) ->
      userId = Meteor.users.findOne({username: username.substring(1)})?._id
      users.push(userId)

    #If no onBehalfOf, submitter is the user.
    submitter = tmpl.find('input[name=onBehalfOf]').value || Meteor.user().username

    queueNames = _.pluck tmpl.findAll('input[name=queueName]:checked'), "value"

    Meteor.call 'checkUsername', submitter, (err, res) ->
      if res
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
            handleErr(tmpl, err.invalidKeys)
          else
            $('#ticketModal').modal('hide')
            
      else
        tmpl.$('input[name=onBehalfOf]').parent().parent().removeClass('has-success').addClass('has-error')
        tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
        tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')

  'click button[data-action=checkUsername]': (e, tmpl) ->
    #Username checking and DOM manipulation for on behalf of submission field.
    unless tmpl.$('input[name="onBehalfOf"]').val() is undefined
      Meteor.call 'checkUsername', tmpl.$('input[name=onBehalfOf]').val(), (err, res) ->
        if res
          tmpl.$('input[name=onBehalfOf]').parent().parent().removeClass('has-error').addClass('has-success')
          tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-ok"></span>')
          tmpl.$('button[data-action=checkUsername]').removeClass('btn-danger').removeClass('btn-primary').addClass('btn-success')
        else
          tmpl.$('input[name=onBehalfOf]').parent().parent().removeClass('has-success').addClass('has-error')
          tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-primary').addClass('btn-danger')
          tmpl.$('button[data-action=checkUsername]').html('<span class="glyphicon glyphicon-remove"></span>')

Template.ticketModal.helpers
  queues: -> Queues.find()



handleErr = (tmpl, invalidKeys) ->
  tmpl.$('.has-error').removeClass('has-error')
  for key in invalidKeys
    tmpl.$('[name='+key.name+']').parent().parent().addClass('has-error')

