package main

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:unicode"
import "core:unicode/utf8"

PROMPT :: "$ "

main :: proc() {
	c_prompt := strings.clone_to_cstring(PROMPT)
	defer delete(c_prompt)

	stack_parent := make([dynamic]i64)
	defer delete(stack_parent)

	for {
		// Read
		c_line := readline(c_prompt)
		if c_line == nil do break
		line := cast(string)c_line

		// Parse
		text := strings.trim(line, "\r\n")
		words, err_words := strings.split(text, " ")
		assert(err_words == nil, "could not split input text")
		defer delete(words)

		// Eval
		stack, err_eval := rpn_eval(words, stack_parent[:])
		if err_eval != .None {
			fmt.eprintln("An error has occurred", err_eval);
			delete(stack)
			continue
		}
		delete(stack_parent)
		stack_parent = stack

		fmt.println(stack_parent)
	}
}
