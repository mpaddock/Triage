if Npm.require('cluster').isMaster
  connectionCount = 0

  logConnectionCount = ->
    console.log 'Current connections: ', connectionCount

  Meteor.setInterval logConnectionCount, 1000*60*5

  Meteor.onConnection (connection) ->
    connectionCount++
    address = connection.httpHeaders['x-forwarded-for'] || connection.clientAddress
    console.log 'New connection from ', address
    logConnectionCount()

    connection.onClose ->
      connectionCount--
      console.log 'Closed connection from ', address
      logConnectionCount()
