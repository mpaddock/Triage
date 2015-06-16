Meteor.startup ->
  Meteor.settings.queues.forEach (x) ->
    Queues.upsert {name: x.name}, {$set: {securityGroups: x.securityGroups}}

Meteor.startup ->
  if Npm.require('cluster').isMaster
    if Meteor.settings.email?.smtpPipe?
      ingestEmailFromSmtpPipe = ->
        fs = Npm.require 'fs'
        console.log 'reading from pipe... waiting for email...'
        fs.readFile Meteor.settings.email.smtpPipe, Meteor.bindEnvironment (err, data) ->
          if (err)
            console.log 'error reading from fifo!'
            return
          else
            console.log 'read data from fifo'
            message = EmailIngestion.parse(data)
            console.log 'message is:', message

            # TODO: Find ticket this is a reply to and attach

            Meteor.setTimeout ingestEmailFromSmtpPipe, 0

      ingestEmailFromSmtpPipe()

