packageSettings =
  name: 'ServerTransform'
  mixins: ['singleton', 'logging']

ServerTransform = class ServerTransform extends PackageBase packageSettings
  @_utils:
    extendFunctions: (obj, dict) ->
      result = {}
      for key of dict
        do (key) ->
          impl = dict[key]

          oldImpl = obj[key]
          obj[key] = impl

          result[key] = (args2...) -> oldImpl.call(args2...)
      return result

  publishTransformed: (name, fn) ->
    Meteor.publish name, ->
      cursors = fn.apply this, arguments
      cursors = [cursors] unless cursors instanceof Array

      for cursor in cursors
        ServerTransform.getInstance().transformedPublication this, cursor

      @ready()

  transformedPublication: (publication, cursor) ->
    collectionName = cursor._cursorDescription.collectionName
    collection = Mongo.Collection.get collectionName
    transform = (doc) ->
      doc = collection.applyServerTransformation doc if collection?
      return doc
    computation = null

    cursor.observe
      added: (doc) ->
        publication.added collectionName, doc._id, transform(doc)

        computation.stop() if computation?
        computation = Tracker.autorun ->
          publication.changed collectionName, doc._id, transform(doc)

      changed: (doc) ->
        publication.changed collectionName, doc._id, transform(doc)

        computation.stop() if computation?
        computation = Tracker.autorun ->
          publication.changed collectionName, doc._id, transform(doc)

      removed: (doc) ->
        publication.removed collectionName, doc._id
