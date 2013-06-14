Number.prototype.clip     or= (min, max)  -> Math.min(max, Math.max(min, this))

String.prototype.matches  or= (exp) ->
  matchObj = toMatchObj _.groupBy(exp.split(' '), commandType)
  _(matchObj.bare).some(makeMatch(@)) and !_(matchObj.except).some(makeMatch(@))



commandType = (command) ->
  return 'except' if command[0] == '-'
  return 'bare'

toMatchObj = (css) ->
  matchObj =
    bare: css[if css[0][0] == '-' then 1 else 0].map toRegex
    except: css[if css[0][0] == '-' then 0 else 1].map((c) -> c[1..]).map toRegex

toRegex = (str) ->
  new RegExp str.replace('*', '[^ \\/:]*').replace(/[^\]]\*\*/, '.*').replace('?', '.')

makeMatch = (str) ->
  (pattern) ->
    str.test pattern
