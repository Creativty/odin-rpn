#+build linux

package main

import "core:c"

foreign import gnu "system:readline"

foreign gnu {
	readline :: proc(prompt: cstring) -> cstring ---
}

