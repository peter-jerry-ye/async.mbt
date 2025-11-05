// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
priv enum State[A] {
  Pending(Array[Handler[A]])
  Fulfilled(A)
  Rejected(Error)
}

///|
priv struct Handler[A]((State[A]) -> Unit)

///|
struct T[A] {
  mut state : State[A]
}

///|
struct Resolver[A](T[A])

///|
pub fn[A] make() -> Resolver[A] {
  Resolver({ state: Pending([]) })
}

///|
pub fn[A] resolve(a : A) -> T[A] {
  { state: Fulfilled(a) }
}

///|
pub fn[A] reject(err : Error) -> T[A] {
  { state: Rejected(err) }
}

///|
pub fn[A] T::get(self : T[A]) -> Result[A, Error]? {
  match self.state {
    Fulfilled(result) => Some(Ok(result))
    Rejected(error) => Some(Err(error))
    _ => None
  }
}

///|
pub fn[A] Resolver::try_complete(
  self : Resolver[A],
  result : () -> A raise,
) -> Bool {
  guard self.state is Pending(_) else { false }
  try result() catch {
    err => self.fullfill_or_reject(Rejected(err))
  } noraise {
    result => self.fullfill_or_reject(Fulfilled(result))
  }
  true
}

///|
pub fn[A] Resolver::resolve(self : Resolver[A], result : A) -> Unit {
  self.fullfill_or_reject(Fulfilled(result))
}

///|
pub fn[A] Resolver::reject(self : Resolver[A], err : Error) -> Unit {
  self.fullfill_or_reject(Rejected(err))
}

///|
fn[A] Resolver::fullfill_or_reject(
  self : Resolver[A],
  state : State[A],
) -> Unit {
  match self.state {
    Pending(handlers) => {
      self.state = state
      for handler in handlers {
        handler(state)
      }
    }
    _ => ()
  }
}

///|
pub fn[A] Resolver::future(self : Resolver[A]) -> T[A] {
  self.0
}

///|
pub fn[A] T::on_success(self : T[A], callback : (A) -> Unit) -> Unit {
  match self.state {
    Fulfilled(a) => callback(a)
    Rejected(_) => ()
    Pending(handlers) =>
      handlers.push(state => if state is Fulfilled(a) { callback(a) })
  }
}

///|
pub fn[A] T::on_failure(self : T[A], callback : (Error) -> Unit) -> Unit {
  match self.state {
    Rejected(err) => callback(err)
    Fulfilled(_) => ()
    Pending(handlers) =>
      handlers.push(state => if state is Rejected(err) { callback(err) })
  }
}

///|
pub fn[A, B] T::bind(self : T[A], callback : (A) -> T[B]) -> T[B] {
  match self.state {
    Fulfilled(a) => callback(a)
    Rejected(err) => reject(err)
    Pending(handlers) => {
      let promise : Resolver[B] = make()
      handlers.push(state => match state {
        Fulfilled(a) => {
          let future = callback(a)
          future.on_success(fn(b) { promise.resolve(b) }) |> ignore
          future.on_failure(fn(err) { promise.reject(err) }) |> ignore
        }
        Rejected(err) => promise.reject(err)
        _ => ()
      })
      promise.future()
    }
  }
}

///|
pub fn[A] T::finally(self : T[A], callback : () -> Unit) -> T[A] {
  match self.state {
    Fulfilled(_) | Rejected(_) => callback()
    Pending(handlers) =>
      handlers.push(state => if state is (Fulfilled(_) | Rejected(_)) {
        callback()
      })
  }
  self
}

///|
pub fn[A] all(promises : Array[T[A]]) -> T[Array[A]] {
  let promise = make()
  let mut count = promises.length()
  let results = Array::make(count, None)
  for i in 0..<count {
    promises[i].on_success(fn(a) {
      results[i] = Some(a)
      count -= 1
      if count == 0 {
        promise.resolve(results.map(Option::unwrap))
      }
    })
    |> ignore
    promises[i].on_failure(fn(err) { promise.reject(err) }) |> ignore
  }
  promise.future()
}

///|
pub suberror AggregateError Array[Error]

///|
pub fn[A] any(promises : Array[T[A]]) -> T[A] {
  let promise = make()
  let mut count = promises.length()
  let errors = Array::make(count, None)
  for i in 0..<count {
    promises[i].on_success(fn(a) { promise.resolve(a) }) |> ignore
    promises[i].on_failure(fn(err) {
      errors[i] = Some(err)
      count -= 1
      if count == 0 {
        promise.reject(AggregateError(errors.map(Option::unwrap)))
      }
    })
    |> ignore
  }
  promise.future()
}

///|
pub fn[A, B] T::zip(self : T[A], that : T[B]) -> T[(A, B)] {
  self.bind(fn(a) { that.bind(fn(b) { resolve((a, b)) }) })
}

///|
pub fn[A, B, C] T::zip_with(self : T[A], that : T[B], f : (A, B) -> C) -> T[C] {
  self.bind(fn(a) { that.bind(fn(b) { resolve(f(a, b)) }) })
}

///|
async fn[A] shift(f : ((A) -> Unit, (Error) -> Unit) -> Unit) -> A = "%async.suspend"

///|
fn reset(f : async () -> Unit noraise) -> Unit = "%async.run"

///|
pub async fn[A] T::await(self : T[A]) -> A {
  shift(fn(resolve : (A) -> Unit, reject : (Error) -> Unit) -> Unit {
    match self.state {
      Fulfilled(a) => resolve(a)
      Rejected(err) => reject(err)
      Pending(handlers) =>
        handlers.push(state => match state {
          Fulfilled(a) => resolve(a)
          Rejected(err) => reject(err)
          _ => ()
        })
    }
  })
}

///|
pub fn[A] spawn(cb : async () -> A) -> T[A] {
  let promise = make()
  reset(async fn() noraise {
    try cb() catch {
      e => promise.reject(e)
    } noraise {
      result => promise.resolve(result)
    }
  })
  promise.future()
}
