Template.ticketModal.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view

Template.ticketModal.helpers
  bodyParagraph: ->
    @body.split('\n')
