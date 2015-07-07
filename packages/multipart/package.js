Package.describe({
  name: 'multipart',
  summary: 'Parse multipart/form-data in iron:router using busboy',
  version: '1.0.0'
});

Npm.depends({
  'connect-busboy': '0.0.2'
});

Package.onUse(function (api) {
  api.use('iron:router');
  api.use('hive:file-registry');
  api.use('coffeescript');
  api.addFiles('multipart.coffee', 'server');
});
