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
add a transform method (you can add multiple methods, not only one)
````javascript
// example: persist the author name on the post object (reactive)
Posts.serverTransform(function(doc) {
  author = Authors.findOne(doc.authorId);
  doc.authorName = author.fullname;

  return doc;
});
````

normally you want to add a custom (computed) property instead of transforming the whole document
````javascript
Posts.computedProperty('commentsCount', function(doc) {
  // example: persist the comments count as a property
  // (without publishing any comments and also reactive!)
  return Comments.find({
    postId: doc._id
  }).count();
});
````

### Publishing
make sure that you publish a `Posts` cursor with `Meteor.publishTransformed` to apply the transformations
````javascript
Meteor.publishTransformed('posts', function() {
  return Posts.find(); // you can also publish multiple cursors by returning an array
});
````
