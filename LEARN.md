# Things to try

Change one thing, run the build, and see what happens. That is the fastest way to learn.

1. In `ContentView.swift` change the start value of `count` to 10.
2. In `Theme.swift` change the three accent numbers and watch the whole app change color.
3. Add a third button that sets `count = 0` (a Reset button).
4. Add `@State private var flag = false` and a `Toggle("Enable", isOn: $flag)`. Show a different text when it is on.
5. Move the counter into its own file `CounterView.swift` and use it from `ContentView`.