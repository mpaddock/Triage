test1 = 'hello @mdpadd2 this is a test #search status:"kljasd"'
test2 = "@vrang2"

Tinytest.add 'Parsers', (test) ->
  if Meteor.isClient
    test.equal Parsers.getTerms(test1), ['hello', 'this', 'is', 'a', 'test']
    test.equal Parsers.getUsernames(test1), ['mdpadd2']
    test.equal Parsers.getStatuses(test1), ['kljasd']

    test.equal Parsers.getTerms(test2), []
    test.equal Parsers.getUsernames(test2), ['vrang2']
