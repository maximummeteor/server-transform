packageSettings =
  name: 'ServerTransform'
  mixins: ['singleton', 'logging']

ServerTransform = class ServerTransform extends PackageBase packageSettings
  publishTransformed: (name, fn) ->
    self = this
    Meteor.publish name, ->
      cursors = fn.apply this, arguments
      cursors = [cursors] unless cursors instanceof Array

      for cursor in cursors
        self.transformedPublication this, cursor

  transformedPublication: (publication, cursor) ->
    transform = cursor.collection.applyServerTranformation
    collectionName = cursor.collection.name
    computation = null

    cursor.observe
      added: (doc) ->
        publication.added collectionName, doc._id, transform(doc)
      changed: (doc) ->
        publication.changed collectionName, doc._id, transform(doc)

        computation = Tracker.autorun ->
          computation.stop() if computation?
          publication.changed collectionName, doc._id, transform(doc)
      removed: (doc) ->
        publication.removed collectionName, doc._id

    publication.ready()
