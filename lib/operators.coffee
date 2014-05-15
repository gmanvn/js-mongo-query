
gt = exports.$gt = (actual, value)-> actual > value
lt = exports.$lt = (actual, value)-> actual < value
gte = exports.$gte = (actual, value)-> actual >= value
lte = exports.$lte = (actual, value)-> actual <= value

where = exports.$where = (actual, where, context)->
  if typeof where is 'string'
    where = "return (#{where})" unless 'return' in where
    where = new Function [], where

  where.call context

