{.this: self.}

import expr, literalType

type
  AstPrinter = ref object of RootObj

proc newAstPrinter*(): AstPrinter =
  return AstPrinter()

proc parenthesize(self: AstPrinter, name: string, exprs: varargs[Expr]): string

method print*(self: AstPrinter, expr: Expr): string {.base.}=
  discard

method print*(self: AstPrinter, expr: Binary): string =
  return parenthesize(expr.operator.lexeme, expr.left, expr.right)

method print*(self: AstPrinter, expr: Grouping): string =
  return parenthesize("group", expr.expression)

method print*(self: AstPrinter, expr: Literal): string =
  return $expr.value

method print*(self: AstPrinter, expr: Unary): string =
  return parenthesize(expr.operator.lexeme, expr.right)

proc parenthesize(self: AstPrinter, name: string, exprs: varargs[Expr]): string =
  result = "(" & name

  for expr in exprs:
    result &= " "
    result &= print(expr)
  
  result &= ")"

when isMainModule:
  import token, tokentype, literalType
  let expression = newBinary(
    newUnary(
      newToken(MINUS, "-", newNilLit(), 1),
      newLiteral(newNumLit(123))
    ),
    newToken(STAR, "*", newNilLit(), 1),
    newGrouping(newLiteral(newNumLit(45.67)))
  )
  let printer = AstPrinter()
  echo printer.print(expression)