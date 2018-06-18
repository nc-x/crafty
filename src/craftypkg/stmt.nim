import expr

type
  Stmt* = ref object of RootObj
    
  ExprStmt* = ref object of Stmt
    expression*: Expr

  PrintStmt* = ref object of Stmt
    expression*: Expr

proc newExprStmt*(e: Expr): ExprStmt =
  return ExprStmt(expression: e)

proc newPrintStmt*(e: Expr): PrintStmt =
  return PrintStmt(expression: e)
