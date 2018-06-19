{.this: self.}

import runtimeerror
import types
import token
import tables

type
  Environment* = object
    values*: Table[string, BaseType]

proc newEnvironment*(): Environment =
  return Environment(values: initTable[string, BaseType]())

proc define*(self: var Environment, name: string, value: BaseType) =
  values[name] = value

proc get*(self: var Environment, name: Token): BaseType =
  if values.contains(name.lexeme):
    return values[name.lexeme]
  
  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")

proc assign*(self: var Environment, name: Token, value: BaseType) =
  if values.contains(name.lexeme):
    values.del(name.lexeme)
    values[name.lexeme] = value
    return
  
  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")
