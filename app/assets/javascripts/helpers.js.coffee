Number.prototype.clip     or= (min, max)  -> Math.min(max, Math.max(min, this))



String.prototype.matches  or= (exp) ->
  matchObj = patternsToRegex _.groupBy(exp.split(' '), commandType)
  take = _(matchObj.bare).some(makeMatch(@))
  drop = !_(matchObj.except).some(makeMatch(@))
  console.log take
  console.log drop
  take and drop

commandType = (command) ->
  return if command[0] is '-' then 'except' else 'bare'

patternsToRegex = (obj) ->
  matchObj =
    bare: if obj.bare
            obj.bare.map toRegex
          else
            []
    except: if obj.except
              obj.except.map((c) -> c[1..]).map toRegex
            else
              []

toRegex = (str) ->
  new RegExp str.replace('.', '\.').replace('*', '[^ \\/:]*').replace(/[^\]]\*\*/, '.*').replace('?', '.')

makeMatch = (str) ->
  (pattern) ->
    pattern.test str
