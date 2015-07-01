busboy = Npm.require 'connect-busboy'

Router.onBeforeAction (req, res, next) ->
  if req.method is 'POST' and req.headers['content-type']?.substr(0,20) is 'multipart/form-data;'
    busboy({immediate: true}).apply @, arguments
  else
    next()

Router.onBeforeAction (req, res, next) ->
  if req.busboy
    req.files = []
    req.body = req.body || {}
    req.busboy.on 'file', Meteor.bindEnvironment (fieldname, file, filename, encoding, mimetype) ->
      # TODO: save in FileRegistry
      file.on 'data', (data) ->
        console.log 'file data'
      file.on 'end', ->
        console.log 'file end'
      req.files.push
        file: file
        fieldname: fieldname
        filename: filename
        encoding: encoding
        mimetype: mimetype
    req.busboy.on 'field', Meteor.bindEnvironment (fieldname, val, fieldnameTruncated, valTruncated) ->
      req.body[fieldname] = val
    req.busboy.on 'finish', Meteor.bindEnvironment ->
      next()
  else
    next()

