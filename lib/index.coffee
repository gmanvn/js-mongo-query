_ = require 'lodash'
operators = require './operators.coffee'

specialOps = Object.keys operators

log4js = require 'log4js'
type = require 'type-component'

###
  object: {
    age: 10
    name: 'loki'
    keywords: ['thor', 'captain', 'marvel']
    emails: [
      { address: 'me@tungv.com', category: 'work' }
      { address: 'gmanvn@gmail.com', category: 'personal' }
    ]
  }

  query: {
    age: $gt: 5
    emails:
      category: 'work'
  }

###

join = (path, key)->
  if path.length then [path, key].join('.') else key

match = (actual, matcher, context)->
  logger = log4js.getLogger 'match'
  logger.setLevel 'ALL'

  logger.debug 'actual', actual
  logger.debug 'matcher', matcher

  switch type matcher
    when 'string', 'number'
      return actual == matcher

    when 'regexp'
      return

    when 'object'
      logger.debug 'object'
      return _.every matcher, (value, key)->
        logger.debug '  key, value', key, value
        if key in specialOps
          return operators[key](actual,value,context)

        ## key == sub path
        subActual = getter actual, key
        return match subActual, value, context



getter = (context, path)->
  fn = new Function 'context', 'return context.' + path
  try fn(context)


queryFn = module.exports = (object, query, path='')->
  logger = log4js.getLogger 'query'

  results = {}
  for key, value of query
    ###
      `key` can be one of 3 cases:
      1. path: need to match that path with the operator
      2. $and, $or: need to iterate over its array
      3. $not: need to revert the inner object
    ###

    switch key
      when '$and'
        logger.debug '$and'
        results[key] = query.$and.every (subQuery)-> queryFn object, subQuery, path
      when '$or'
        logger.debug '$or'
        results[key] = query.$or.some (subQuery)-> queryFn object, subQuery, path
      when '$not'
        logger.debug '$not'
        results[key] = !queryFn object, query.$not, path
      else
        logger.debug 'path', key
        actual = getter object, join path, key
        results[key] = match actual, value, context

  logger.debug 'results', results, path

  return _.all results, (bool)-> bool is true