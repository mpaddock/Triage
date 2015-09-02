Template.ticketModal.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view

  'keydown': (e, tpl) ->
    console.log e.keyCode
    if e.keyCode is 27
      $('#ticketModal').modal('hide')

Template.ticketModal.helpers
  bodyParagraph: ->
    @body.split('\n')
