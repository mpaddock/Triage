Package.describe({
  name: 'multipart',
  summary: 'Add multipart parsing to router using busboy',
  version: '1.0.0'
});

Npm.depends({
  'connect-busboy': '0.0.2'
});

Package.onUse(function (api) {
  api.use('iron:router')
  api.use('coffeescript')
  api.addFiles('multipart.coffee', 'server');
});
