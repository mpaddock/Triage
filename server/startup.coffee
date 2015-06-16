Meteor.startup ->
  Meteor.settings.queues.forEach (x) ->
    Queues.upsert {name: x.name}, {$set: {securityGroups: x.securityGroups}}

  if Npm.require('cluster').isMaster
    ingestEmailFromSmtpPipe = ->
      fs = Npm.require 'fs'
      console.log 'reading from pipe... waiting for email...'
      fs.readFile '/Users/asuser/testfifo', Meteor.bindEnvironment (err, data) ->
        if (err)
          console.log 'error reading from fifo!'
          return
        else
          console.log 'read data from fifo'
          message = EmailIngestion.parse(data)
          console.log 'message is:', message

          Meteor.setTimeout ingestEmailFromSmtpPipe, 0

    ingestEmailFromSmtpPipe()

