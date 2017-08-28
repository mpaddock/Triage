{expect, assert} = require 'chai'
{Parsers} = require './parsers.coffee'

test1 = 'hello @mdpadd2 this is a test #search status:"kljasd"'
test2 = "@vrang2"

tagsTest1 = "#tag/with/slash #tag-with-hyphen #tag_with_underscore" # tags with special characters
tagsTest2 = "#fff #000 #abc #f1f1f1 #f1f1 #f1f1f1wordafter" #hex codes and hex code similar tags
tagsTest3 = "waggle# waggle#test #test" #middle of word tags

content1 = "This is now done.\nThanks,\nPerson"
result1  = "<p>This is now done.</p><p>Thanks,</p><p>Person</p>"

content2 = "There are < 2 reasons to use < in place of 'less than' in a sentence.\nBut I did it anyway, because this is a test."
result2 = "<p>There are &lt; 2 reasons to use &lt; in place of &#x27;less than&#x27; in a sentence.</p>" +
  "<p>But I did it anyway, because this is a test.</p>"

if Meteor.isClient
  describe 'Parsers', ->
    it 'usernames and statuses', ->
      expect(Parsers.getTerms(test1)).to.deep.equal ['hello', 'this', 'is', 'a', 'test']
      expect(Parsers.getUsernames(test1)).to.deep.equal ['mdpadd2']
      expect(Parsers.getStatuses(test1)).to.deep.equal ['kljasd']

      expect(Parsers.getTerms(test2)).to.deep.equal []
      expect(Parsers.getUsernames(test2)).to.deep.equal ['vrang2']

    it 'hashtags and hex codes', ->
      expect(Parsers.getTags(tagsTest1)).to.deep.equal [ 'tag/with/slash', 'tag-with-hyphen', 'tag_with_underscore' ]
      expect(Parsers.getTags(tagsTest2)).to.deep.equal [ 'f1f1', 'f1f1f1wordafter' ]
      expect(Parsers.getTags(tagsTest3)).to.deep.equal [ 'test' ]

if Meteor.isServer
  describe 'Parsers', ->
    it 'email content parsing on server', ->
      expect(Parsers.prepareContentForEmail(content1)).to.equal result1
      expect(Parsers.prepareContentForEmail(content2)).to.equal result2

describe 'Parsers', ->
  it 'should not match numeric hashtags', ->
    expect(Parsers.getTags("#string #1234")).to.deep.equal ['string']
    expect(Parsers.getTags("#alpha #5678 #beta")).to.deep.equal ['alpha', 'beta']

