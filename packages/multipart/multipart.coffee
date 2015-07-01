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
      fs = Npm.require 'fs'

      size = 0
      now = Date.now()
      filenameOnDisk = "#{filename}-#{now}"
      file.pipe fs.createWriteStream (FileRegistry.getFileRoot() + filenameOnDisk)
      file.on 'data', (data) ->
        size += data.length
      file.on 'end', Meteor.bindEnvironment ->
        f = _id: FileRegistry.insert
          filename: filename
          filenameOnDisk: filenameOnDisk
          size: size
          timestamp: now
        FileRegistry.scheduleJobsForFile filenameOnDisk
        req.files.push f

    req.busboy.on 'field', Meteor.bindEnvironment (fieldname, val, fieldnameTruncated, valTruncated) ->
      req.body[fieldname] = val
    req.busboy.on 'finish', Meteor.bindEnvironment ->
      next()
  else
    next()

