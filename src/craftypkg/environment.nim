{.this: self.}

import runtimeerror
import types
import token
import tables

type
  Environment* = ref object
    enclosing*: Environment
    values*: Table[string, BaseType]

proc newEnvironment*(): Environment =
  return Environment(enclosing: nil, values: initTable[string, BaseType]())

proc newEnvironment*(enclosing: Environment): Environment =
  return Environment(enclosing: enclosing, values: initTable[string, BaseType]())

proc define*(self: var Environment, name: string, value: BaseType) =
  values[name] = value

proc ancestor(self: var Environment, distance: int): Environment =
  var environment = self
  for i in 0 ..< distance:
    environment = environment.enclosing
  return environment

proc get*(self: var Environment, name: Token): BaseType =
  if values.contains(name.lexeme):
    return values[name.lexeme]

  if enclosing != nil:
    return enclosing.get(name)
  
  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")

proc getAt*(self: var Environment, distance: int, name: string): BaseType =
  return ancestor(distance).values[name]

proc assign*(self: var Environment, name: Token, value: BaseType) =
  if values.contains(name.lexeme):
    values.del(name.lexeme)
    values[name.lexeme] = value
    return

  if enclosing != nil:
    enclosing.assign(name, value)
    return
  
  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")

proc assignAt*(self: var Environment, distance: int, name: Token, value: BaseType) =
  if ancestor(distance).values.contains(name.lexeme):
    ancestor(distance).values.del(name.lexeme)
  ancestor(distance).values.add(name.lexeme, value)
