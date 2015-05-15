if (typeof Meteor !== 'undefined') return;

Package.describe({
  name: 'triage-tinytest',
  summary: 'tinytest package for Triage app'
});

Package.onUse(function (api) {
  api.use([
    'mongo',
    'coffeescript',
    'aldeed:collection2'
  ]);
  api.addFiles([
    'lib/facets.coffee'
  ]);
});

Package.onTest(function (api) {
  api.use([
    'mongo',
    'coffeescript',
    'aldeed:collection2@2.3.3',
    'aldeed:simple-schema@1.3.2',
    'matb33:collection-hooks@0.7.13',
    'tinytest',
    'test-helpers'
  ]);

  api.addFiles([
    'lib/collections.coffee',
    'lib/facets.coffee',
    'tests/facets-test.coffee'
  ], ['client', 'server']);
});

