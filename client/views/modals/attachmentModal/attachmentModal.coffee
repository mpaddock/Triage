Template.attachmentModal.helpers
  attachment: ->
    return FileRegistry.findOne @attachmentId
  fileIsImage: ->
    _.contains [ 'jpg', 'jpeg', 'gif', 'bmp', 'png', 'tiff', 'tif', 'cr2', 'tga' ], @filename.substr(@filename.lastIndexOf('.')+1).toLowerCase()
  fileIsPdf: ->
    @filename.substr(@filename.indexOf('.')+1) is 'pdf'

Template.attachmentModal.events
  'hidden.bs.modal': (e, tpl) ->
    Iron.query.set 'attachmentId', null
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $(document.body).addClass('modal-open')

  'show.bs.modal': (e, tpl) ->
    setTimeout ->
      $('.modal-backdrop').not('.modal-ticket').css('z-index',  1069)
    , 10


