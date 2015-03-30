(exports ? this).unique = (value, index, self) ->
  #filter function for unique arrays.
  self.indexOf(value) is index

Handlebars.registerHelper 'arrayify', (obj) ->
  result = []
  for k,v of obj
    result.push {
      name: k
      value: v
    }
  return result

(exports ? this).getMediaFunctions = ->
  requiredFunctions = ['pickLocalFile', 'capturePhoto', 'captureAudio', 'captureVideo']
  if Meteor.isCordova
    CordovaMedia
  else
    WebMedia

(exports ? this).getTags = (text) ->
  text.match(/#\S+/g)?.filter unique

(exports ? this).getUsers = (text) ->
  usertags = text.match(/\@\S+/g)
  users = []
  _.each usertags, (username) ->
    userId = Meteor.users.findOne({username: username.substring(1)})?._id
    if userId then users.push(userId)
  return users.filter unique
