package main

import "core:slice"
import "core:strings"
import "core:strconv"
import "core:unicode"
import "core:unicode/utf8"

Operation :: enum {
	Add,
	Subtract,
	Multiply,
	Division,
	Modulo,
}

Token :: union {
	i64,
	Operation,
}

token_match :: proc(repr: string) -> Token {
	switch repr {
	case "+":
		return Operation.Add
	case "-":
		return Operation.Subtract
	case "*":
		return Operation.Multiply
	case "/":
		return Operation.Division
	case "%":
		return Operation.Modulo
	}
	runes := utf8.string_to_runes(repr)
	if slice.all_of_proc(runes, unicode.is_digit) {
		n, ok := strconv.parse_i64_maybe_prefixed(repr)
		if ok do return n
	}
	return nil
}

parse :: proc(words: []string, allocator := context.allocator) -> [dynamic]Token {
	tokens := make([dynamic]Token)
	for word in words do append(&tokens, token_match(word))
	return tokens
}

Eval_Error :: enum {
	None,
	Unknown_Token,
	Division_Zero,
	Mismatch_Arguments,
}

rpn_operation :: proc(stack: ^[dynamic]i64, op: Operation) -> Eval_Error {
	length := len(stack^)
	switch op {
	case .Modulo:
		if length < 2 do return .Mismatch_Arguments
		b, a := pop(stack), pop(stack)
		append(stack, a % b)
	case .Division:
		if length < 2 do return .Mismatch_Arguments
		b, a := pop(stack), pop(stack)
		if b == 0 do return .Division_Zero
		append(stack, a / b)
	case .Multiply:
		if length < 2 do return .Mismatch_Arguments
		b, a := pop(stack), pop(stack)
		append(stack, a * b)
	case .Subtract:
		if length < 1 do return .Mismatch_Arguments
		b := pop(stack)
		if len(stack) == 0 {
			append(stack, -b)
		} else {
			a := pop(stack)
			append(stack, a - b)
		}
	case .Add:
		if length < 1 do return .Mismatch_Arguments
		b := pop(stack)
		if len(stack) == 0 {
			append(stack, +b)
		} else {
			a := pop(stack)
			append(stack, a + b)
		}
	}
	return .None
}

rpn_eval :: proc(words: []string, parent_stack: []i64) -> ([dynamic]i64, Eval_Error) {
	tokens := parse(words)
	defer delete(tokens)
	if slice.any_of(tokens[:], nil) do return nil, .Unknown_Token

	err := Eval_Error.None
	stack := make([dynamic]i64)
	for number in parent_stack do append(&stack, number)
	for token in tokens {
		switch val in token {
		case i64:
			append(&stack, val)
		case Operation:
			err = rpn_operation(&stack, val)
			if err != .None do break
		}
	}
	return stack, .None
}
