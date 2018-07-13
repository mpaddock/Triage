if Meteor.isProduction
  #if Npm.require('cluster').isMaster
  originalLog = console.log
  console.log = ->
    if arguments[0] == 'LISTENING'
      originalLog.apply this, arguments
    else
      args = [new Date().toLocaleString()+"  "].concat(Array.prototype.slice.call(arguments))
      originalLog.apply this, args
