# [Crafting Interpreters](https://craftinginterpreters.com/) in Nim

`nimble build` to compile and then run the resulting binary

Example
=======

`File: hello.craft`
```
class Hello {
	greet() {
		print "hello";
	}
}

var h = Hello();
h.greet();
```

`crafty hello.craft` => `hello`
