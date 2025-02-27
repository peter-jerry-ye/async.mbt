# Async Library

This library provides

- `promise`: a normal promise library
- `loop`: an event loop implementation

## Promise

It provides a `Resolver[A]`, which provides methods to fulfill a promise/future `T[A]`, which can be retrieved from
`resolver.future()`.

The `T[A]` provides several useful functions, such as `bind` and `finally`.

It also contains conversion to/from the `async` function in MoonBit with:

- `spawn`: Takes an `async fn (defer) -> A!`, which is executed right away, and returns a `T[A]`. The `defer` accepts callbacks and will execute when the async function finishes
- `t.await()`: Awaits for the result of `T[A]` in the async context.

## Event loop

It provides an event loop `T[A]`, where `A` should fulfill a trait `Sync` that can sync on an array of elements and return the index of the elements that are ready. The element can be, for example, pollable from the WASI implementation.

The event loop creates a `Handler` with `on_ready` that takes a callback, which will be executed every time the corresponding `Sync` is ready. The user should call the `handler.stop` from within the callbacks to terminate the `Handler`.

The event loop can `run_until` a condition is met, or `run` until all the handlers are emptied.