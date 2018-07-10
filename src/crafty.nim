import os
import craftypkg / [ error, scanner, token, parser, astprinter, runtimeerror, interpreter, resolver ]

let ip = newInterpreter()

proc run(source: string) =
  var scanner = newScanner(source)
  var tokens = scanner.scanTokens()
  var parser = newParser(tokens)
  var statements = parser.parse()

  if hadError: return

  var resolver = newResolver(ip)
  resolver.resolve(statements)

  if hadError: return

  ip.interpret(statements)

proc runFile(path: string) =
  var content = readFile(path)
  run(content)

  if hadError: quit(65)
  if hadRuntimeError: quit(70)

proc runPrompt() =
  while true:
    stdout.write "> "
    run(stdin.readLine())
    hadError = false

proc main() =
  var args = commandLineParams()
  if args.len > 1:
    echo "Usage: crafty [script]"
  elif args.len == 1:
    runFile(args[0])
  else:
    runPrompt()

main()
