(exports ? this).unique = (value, index, self) ->
  #Function for filtering arrays to ensure unique objects. array.filter(unique) will return a new array with only unique values. 
  self.indexOf(value) is index

Handlebars.registerHelper 'arrayify', (obj) ->
  #Transforms objects with k/v pairs into arrays of objects so Handlebars can iterate over them properly.
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
  #Scans a body of text for hashtags (#hashtag), returns an array of unique results.
  text.match(/#\S+/g)?.filter unique

(exports ? this).getUsers = (text) ->
  #Scans a body of text for user tags (@username), and then searches Meteor.users by username and returns an array of unique userIds.
  usertags = text.match(/\@\S+/g)
  users = []
  _.each usertags, (username) ->
    userId = Meteor.users.findOne({username: username.substring(1)})?._id
    if userId then users.push(userId)
  return users.filter unique
