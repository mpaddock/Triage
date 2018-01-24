Template.infoModal.helpers
  message: -> Session.get('infoMessage')
  header: -> Session.get('infoHeader')

Template.infoModal.events
  'hidden.bs.modal': (e, tpl) ->
    Session.set('infoMessage', null)
    Session.set('infoHeader', null)
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $(document.body).addClass('modal-open')

  'show.bs.modal': (e, tpl) ->
    zIndex = 1040 + ( 10 * $('.modal:visible').length)
    $(e.target).css('z-index', zIndex)
    setTimeout ->
      $('.modal-backdrop').not('.modal-stack').css('z-index',  zIndex-1).addClass('modal-stack')
    , 10


