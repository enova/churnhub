Number.prototype.clip     or= (min, max)  -> Math.min(max, Math.max(min, this))



String.prototype.matches  or= (exp) ->
  matchObj = patternsToRegex _.groupBy(exp.trim().split(' '), commandType)
  take = _(matchObj.bare).some(makeMatch(this))
  drop = !_(matchObj.except).some(makeMatch(this))
  take and drop

commandType = (command) ->
  return if command[0] is '-' then 'except' else 'bare'

patternsToRegex = (obj) ->
  matchObj =
    bare:
      if obj.bare
        obj.bare.map toRegex
      else
        [/.*/]
    except:
      if obj.except
        toRegex(pattern[1 ..]) for pattern in obj.except when pattern.length > 1
      else
        []

toRegex = (str) ->
  new RegExp str.replace('.', '\\.').replace('*', '[^ \\/:]*').replace(/[^\]]\*\*/, '.*').replace('?', '.')

makeMatch = (str) ->
  (pattern) ->
    pattern.test str
