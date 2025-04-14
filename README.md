# Async Library

This library provides

- `promise`: a normal promise library
- `loop`: an event loop implementation
- `channel`: a channel library
- `stream`: an abstraction over i/o

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

## Channel

It provides a channel `T[A]`, where `A` could be anything.

The `T[A]` has async operations such as `pop` and `push`. More APIs are to be implemented based on feedback.

## Stream

It defines a few traits : 
- basic traits: `Closable` `Flushable`
- i/o based on bytes: `InputStream` `OutputStream`
- i/o based on chars: `Reader` `Writer`

It also provides some simple function to convert, for example, an `InputStream` to a `Reader`, and a `Reader` to a `BufferedReader`. Users have Java background may be familiar with this hierarchy.

## TODO

- Adjust APIs based on feedbacks
- Add documents
- Add tests
