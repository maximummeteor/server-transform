Meteor.startup ->
  Posts = new Mongo.Collection 'posts'
  Comments = new Mongo.Collection 'comments'

  if Meteor.isServer
    Comments.allow
      insert: -> true
      update: -> true
      remove: -> true
    Comments.deny
      insert: -> false
      update: -> false
      remove: -> false

    Posts.remove {}
    Comments.remove {}

    id = Posts.insert name: 'Test'
    Comments.insert postId: id, text: 'Hello'

    Posts.serverTransform (doc) ->
      doc.commentsCount = Comments.find({postId: doc._id}, reactive: true).count()
      return doc

    Meteor.publishTransformed 'posts_1', ->
      Posts.find()

    Meteor.publishTransformed 'posts_2', ->
      Posts.find().serverTransform (doc) ->
        doc.test_2 = true
        return doc

    Meteor.publishTransformed 'posts_3', ->
      Posts.find().serverTransform test_3: true

    Tinytest.add 'ServerTransform - single property', (test) ->
      Comments.serverTransform
        authorName: (doc) ->
          return 'max'

      comment = Comments.findOne()
      comment = ServerTransform.getInstance().applyTransformations Comments._serverTransformations, comment

      test.equal comment.authorName, 'max'


  if Meteor.isClient
    Tinytest.addAsync 'ServerTransform - simple', (test, next) ->
      Meteor.subscribe 'posts_1', ->
        test.isTrue Posts.find().count() > 0
        post = Posts.findOne()
        Comments.insert postId: post._id, text: 'Hello'
        Meteor.setTimeout ->
          test.isTrue Posts.findOne(post._id).commentsCount > 1
          next()
        , 2000

    Tinytest.addAsync 'ServerTransform - local transform', (test, next) ->
      Meteor.subscribe 'posts_2', ->
        post = Posts.findOne()
        test.isTrue post.test_2
        next()

    Tinytest.addAsync 'ServerTransform - local transform with object definition', (test, next) ->
      Meteor.subscribe 'posts_3', ->
        post = Posts.findOne()
        test.isTrue post.test_3
        next()
