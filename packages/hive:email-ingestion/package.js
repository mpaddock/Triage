Package.describe({
  name: 'hive:email-ingestion',
  version: '0.0.2',
  summary: '',
  git: '',
  documentation: 'README.md'
});

Npm.depends({
  'mailparser': '0.5.1'
});

Package.onUse(function(api) {
  api.versionsFrom('1.3');
  api.use(['modules', 'coffeescript', 'hive:file-registry', 'underscore'], 'server');
  api.addFiles('email-ingestion.coffee', 'server');
  api.export('EmailIngestion', 'server');
});

Package.onTest(function(api) {
  api.use('dispatch:mocha-phantomjs');
  api.use(['coffeescript', 'underscore', 'check', 'modules', 'hive:file-registry']);
  api.use('hive:email-ingestion');
  api.addFiles('email-ingestion-tests.coffee', 'server');
});
