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

proc get*(self: var Environment, name: Token): BaseType =
  if values.contains(name.lexeme):
    return values[name.lexeme]

  if enclosing != nil:
    return enclosing.get(name)
  
  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")

proc assign*(self: var Environment, name: Token, value: BaseType) =
  if values.contains(name.lexeme):
    values.del(name.lexeme)
    values[name.lexeme] = value
    return

  if enclosing != nil:
    enclosing.assign(name, value)
    return
  
  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")
