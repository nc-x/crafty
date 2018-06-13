import strformat

var hadError* = false

# Forward Declaration
proc report(line: int, where: string, message: string)

# Proc
proc error*(line: int, message: string) =
  report(line, "", message)

proc report(line: int, where: string, message: string) =
  echo &"[line {$line}] Error{$where}: {$message}"
  hadError = true
