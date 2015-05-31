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

    Meteor.publishTransformed 'posts', ->
      Posts.find()

  if Meteor.isClient
    Tinytest.addAsync 'ServerTransform - simple', (test, next) ->
      Meteor.subscribe 'posts', ->
        test.isTrue Posts.find().count() > 0
        post = Posts.findOne()
        Comments.insert postId: post._id, text: 'Hello'
        Meteor.setTimeout ->
          test.isTrue Posts.findOne(post._id).commentsCount > 1
          next()
        , 2000
