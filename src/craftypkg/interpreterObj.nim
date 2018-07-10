import environment, tables, expr, objhashes

type
  Interpreter* = ref object of RootObj
    globals*: Environment
    environment*: Environment
    locals*: Table[Expr, int]

proc resolve*(self: var Interpreter, expr: Expr, depth: int) =
  self.locals.add(expr, depth)
