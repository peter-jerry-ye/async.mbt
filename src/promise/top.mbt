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
priv type Handler[A] (State[A]) -> Unit

///|
struct T[A] {
  mut state : State[A]
}

///|
type Resolver[A] T[A]

///|
pub fn make[A]() -> Resolver[A] {
  Resolver({ state: Pending([]) })
}

///|
pub fn resolve[A](a : A) -> T[A] {
  { state: Fulfilled(a) }
}

///|
pub fn reject[A](err : Error) -> T[A] {
  { state: Rejected(err) }
}

///|
pub fn get[A](self : T[A]) -> Result[A, Error]? {
  match self.state {
    Fulfilled(result) => Some(Ok(result))
    Rejected(error) => Some(Err(error))
    _ => None
  }
}

///|
pub fn try_complete[A](self : Resolver[A], result : () -> A!) -> Bool {
  guard self.state is Pending(_) else { false }
  try {
    result!()
  } catch {
    err => self.fullfill_or_reject(Rejected(err))
  } else {
    result => self.fullfill_or_reject(Fulfilled(result))
  }
  true
}

///|
pub fn Resolver::resolve[A](self : Resolver[A], result : A) -> Unit {
  fullfill_or_reject(self, Fulfilled(result))
}

///|
pub fn Resolver::reject[A](self : Resolver[A], err : Error) -> Unit {
  fullfill_or_reject(self, Rejected(err))
}

///|
fn fullfill_or_reject[A](self : Resolver[A], state : State[A]) -> Unit {
  match self.state {
    Pending(handlers) => {
      self.state = state
      for handler in handlers {
        (handler._)(state)
      }
    }
    _ => ()
  }
}

///|
pub fn future[A](self : Resolver[A]) -> T[A] {
  self._
}

///|
pub fn on_success[A](self : T[A], callback : (A) -> Unit) -> Unit {
  match self.state {
    Fulfilled(a) => callback(a)
    Rejected(_) => ()
    Pending(handlers) =>
      handlers.push(fn {
        Fulfilled(a) => callback(a)
        _ => ()
      })
  }
}

///|
pub fn on_failure[A](self : T[A], callback : (Error) -> Unit) -> Unit {
  match self.state {
    Rejected(err) => callback(err)
    Fulfilled(_) => ()
    Pending(handlers) =>
      handlers.push(fn {
        Rejected(err) => callback(err)
        _ => ()
      })
  }
}

///|
pub fn bind[A, B](self : T[A], callback : (A) -> T[B]) -> T[B] {
  match self.state {
    Fulfilled(a) => callback(a)
    Rejected(err) => reject(err)
    Pending(handlers) => {
      let promise : Resolver[B] = make()
      handlers.push(fn {
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
pub fn finally[A](self : T[A], callback : () -> Unit) -> T[A] {
  match self.state {
    Fulfilled(_) | Rejected(_) => callback()
    Pending(handlers) =>
      handlers.push(fn {
        Fulfilled(_) | Rejected(_) => callback()
        _ => ()
      })
  }
  self
}

///|
pub fn all[A](promises : Array[T[A]]) -> T[Array[A]] {
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
pub type! AggregateError Array[Error]

///|
pub fn any[A](promises : Array[T[A]]) -> T[A] {
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
pub fn zip[A, B](self : T[A], that : T[B]) -> T[(A, B)] {
  self.bind(fn(a) { that.bind(fn(b) { resolve((a, b)) }) })
}

///|
pub fn zip_with[A, B, C](self : T[A], that : T[B], f : (A, B) -> C) -> T[C] {
  self.bind(fn(a) { that.bind(fn(b) { resolve(f(a, b)) }) })
}

///|
async fn shift[A](f : ((A) -> Unit, (Error) -> Unit) -> Unit) -> A! = "%async.suspend"

///|
fn reset(f : async () -> Unit) -> Unit = "%async.run"

///|
pub async fn await[A](self : T[A]) -> A! {
  shift!(fn(resume : (A) -> Unit, reject : (Error) -> Unit) -> Unit {
    self.on_success(resume)
    self.on_failure(reject)
  })
}

///|
pub fn spawn[A](cb : async ((() -> Unit) -> Unit) -> A!) -> T[A] {
  let promise = make()
  let defer : Array[() -> Unit] = []
  promise
  .future()
  .finally(fn() {
    for func in defer.rev_iter() {
      func()
    }
  })
  |> ignore
  reset(async fn() {
    try {
      cb!(fn(finally) { defer.push(finally) })
    } catch {
      e => promise.reject(e)
    } else {
      result => promise.resolve(result)
    }
  })
  promise.future()
}
