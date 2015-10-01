Template.ticketModal.events
  'show.bs.modal': (e, tpl) ->
    zIndex = 1040 + ( 10 * $('.modal:visible').length )
    $(e.target).css('z-index', zIndex)
    setTimeout ->
      $('.modal-backdrop').not('.modal-stack').css('z-index', zIndex - 1).addClass('modal-stack')
    , 0
  'hidden.bs.modal': (e, tpl) ->
    Iron.query.set 'ticket', null
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $('body').addClass('modal-open')

  'click a[name=ticketLink]': (e, tpl) ->
    # Have to hide the modal manually when clicking the direct link to the ticket page. Could do away with
    # the whole 'ticket page' concept and have those routes point to the queue + modal?
    tpl.$('#ticketModal').modal('hide')

Template.ticketModal.helpers
  ticket: -> Tickets.findOne(@ticketId)
  bodyParagraph: ->
    @body.split('\n')
