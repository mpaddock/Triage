Template.ticketModal.events
  'hidden.bs.modal #ticketModal': (e, tmpl) ->
    tmpl.$(':input').val('')
    tmpl.$('.has-error').removeClass('has-error')
    tmpl.$('button[data-action=checkUsername]').removeClass('btn-success').removeClass('btn-danger').addClass('btn-primary').html('Check')
 
  'click button[data-action=submit]': (e, tmpl) ->
    #Probably need a record of 'true' submitter for on behalf of submissions.
    submitter = tmpl.find('input[name=onBehalfOf]').value || Meteor.user().username
    queueNames = _.pluck tmpl.findAll('input[name=queueName]:checked'), "value"
    Meteor.call 'checkUsername', submitter, (err, res) ->
      if res
        Tickets.insert {
          title: tmpl.find('input[name=title]').value
          body: tmpl.find('textarea[name=body]').value
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

