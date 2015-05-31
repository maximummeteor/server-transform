# Meteor serverside transform [![Build Status](https://travis-ci.org/maximummeteor/server-transform.svg)](https://travis-ci.org/maximummeteor/server-transform)
Meteor package to transform documents on publish

## Installation

```
    meteor add maximum:server-transform
```

## Usage

Initialize a collection
````javascript
var Posts = new Mongo.Collection('posts');
````

### Configure Transformations
add a transform method to an collection object or a cursor (you can add multiple methods, not only one)
````javascript
// example: persist the author name on the post object (reactive)
Posts.serverTransform(function(doc) {
  author = Authors.findOne(doc.authorId);
  doc.authorName = author.fullname;

  return doc;
});

//transform a cursor (only in a publishTransformed method)
Posts.find().serverTransform(function(doc) {
  author = Authors.findOne(doc.authorId);
  doc.authorName = author.fullname;

  return doc;
});
````

normally you want to add custom (computed) properties instead of transforming the whole document. You can do this by passing an object to `serverTransform`.
````javascript
Posts.serverTransform({
  // example: persist the comments count as a property
  // (without publishing any comments and also reactive!)
  commentsCount: function(doc) {
    return Comments.find({
      postId: doc._id
    }).count();
  }
});
````

If a computed property returns a new cursor, the cursor will also be transformed and published (this works recursively)

````javascript
Posts.serverTransform({
  allAuthors: function(doc) {
    return Authors.find({
      postId: doc._id
    }, {
      reactive: true
    });
  }
});
````

### Publishing
make sure that you publish a `Posts` cursor with `Meteor.publishTransformed` to apply the transformations
````javascript
Meteor.publishTransformed('posts', function() {
  return Posts.find(); // you can also publish multiple cursors by returning an array
});
````

sometimes you only want local transformations.
````javascript
Meteor.publishTransformed('posts_2', function() {
  return Posts.find().serverTransform({
    // we extending the document with the custom property 'commentsCount'
    commentsCount: function(doc) {
      return Comments.find({
        postId: doc._id
      }).count();
    }
  });
});
````
