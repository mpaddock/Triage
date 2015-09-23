Template.ticketModal.events
  'show.bs.modal': (e, tpl) ->
    setTimeout ->
      $('.modal-backdrop').not('.modal-attachment').addClass('modal-ticket')
    , 0
  'hidden.bs.modal': (e, tpl) ->
    Iron.query.set 'ticket', null
    Blaze.remove tpl.view

  'click a[name=ticketLink]': (e, tpl) ->
    # Have to hide the modal manually when clicking the direct link to the ticket page. Could do away with
    # the whole 'ticket page' concept and have those routes point to the queue + modal?
    tpl.$('#ticketModal').modal('hide')

Template.ticketModal.helpers
  ticket: -> Tickets.findOne(@ticketId)
  bodyParagraph: ->
    @body.split('\n')
