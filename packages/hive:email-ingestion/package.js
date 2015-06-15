Package.describe({
  name: 'hive:email-ingestion',
  version: '0.0.1',
  summary: '',
  git: '',
  documentation: 'README.md'
});

Npm.depends({
  'mailparser': '0.5.1'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');
  api.use('coffeescript', 'server');
  api.addFiles('email-ingestion.coffee', 'server');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('coffeescript');
  api.use('hive:email-ingestion');
  api.addFiles('email-ingestion-tests.coffee');
});
