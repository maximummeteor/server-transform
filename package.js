Package.describe({
  name: 'maximum:server-transform',
  version: '0.3.10',
  summary: 'Meteor package to transform documents on publish',
  git: 'https://github.com/maximummeteor/server-transform',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');
  api.use([
    'coffeescript',
    'mongo',
    'maximum:package-base@1.1.2',
    'maximum:reactive-cursors@0.1.0',
    'dburles:mongo-collection-instances@0.3.3',
    'peerlibrary:server-autorun@0.2.6'
  ]);

  api.addFiles([
    'publish_helper.coffee',
    'server-transform.coffee',
    'extend.coffee'
  ], 'server');

  api.export('ServerTransform');
});

Package.onTest(function(api) {
  api.use([
    'tinytest',
    'coffeescript',
    'maximum:server-transform'
  ]);
  api.addFiles('tests/server-transform.coffee');
});
