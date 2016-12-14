{expect} = require 'chai'
{EmailIngestion} = require './email-ingestion.coffee'

fs = Npm.require('fs')

emaildir = process.env.PWD+'/packages/hive:email-ingestion/emails/'

testFiles = [
  {
    file: 'uky_forwarded_to_gmail.mail'
    expected: "I use gmail--my uk email is forwarded to a gmail account.\n\nWaggle User"
  },
  {
    file: 'outlook_web_app.mail'
    expected: "This sholud definitely become a comment."
  },
  {
    file: 'base64_plaintext.mail'
    expected: 'This is a reply.'
  },
  {
    file: 'reply_with_attachment.mail'
    expected: 'An attachment'
  },
  {
    file: 'reply_with_attachment2.mail',
    expected: "Sorry for the slow response.\n\n"+
    "I was away when you sent the first request adn then it got lost in the"+
    "\nflood.\n\n"+
    "This message has a pdf file attached."
  },
  {
    file: 'uky_forwarded_to_gmail2.mail'
    expected: 'test'
  },
  {
    file: 'iphone.mail'
    expected: 'How soon can you ?'
  }
]

describe 'Email ingestion', ->
  it 'ingest reply parsing', ->
    _.each testFiles, (t) ->
      parsed = EmailIngestion.parse fs.readFileSync("#{emaildir}/#{t.file}")
      check parsed.subject, String
      check parsed.body, String
      check parsed.attachments, Array
      check parsed.headers, Object
      check parsed.fromEmail, String #SimpleSchema.RegEx.Email
      check parsed.toEmails, [String]

      expect(JSON.stringify(EmailIngestion.extractReplyFromBody(parsed.body, parsed.toEmails))).to.equal JSON.stringify(t.expected)

  it 'quoted-text marker strings', ->
    good = [
      'On Wed, Jul 15, 2015 at 1:21 PM, <triagebot@triage.as.uky.edu> wrote:',
      '________________________________\nFrom:'
    ]

    bad = [
      'On or around May 26th, I did something.\nwrote:',
      '________________________________\nJohn Doe'
    ]

    # If it's a real quote-text delimiter, we just get the preceding text as the body
    _.each good, (g) -> expect('').to.equal EmailIngestion.extractReplyFromBody g

    # If it's actually body text that _looks_ like a quote-text delimiter, we
    # should get the body text back
    _.each bad, (b) -> expect(b).to.equal EmailIngestion.extractReplyFromBody b

