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
pub fn[A] new() -> T[A] {
  { handlers: Map::new() }
}

///|
fn[A] T::add_handler(
  self : T[A],
  id : UInt64,
  subscribe : A,
  action : Handler,
) -> Unit {
  self.handlers[id] = (subscribe, action)
}

///|
fn[A] T::remove_handler(self : T[A], id : UInt64) -> Unit {
  self.handlers.remove(id)
}

///|
fn[A : Sync] iter(engine : T[A]) -> Unit {
  let values = engine.handlers.values().collect()
  let wait = values.map(fn(pair) { pair.0 })
  let result = A::sync(wait)
  result.each(fn(id) {
    let handle = values[id.reinterpret_as_int()].1
    if not(handle.is_stopped()) {
      values[id.reinterpret_as_int()].1.start()
    }
  })
}

///|
fn make_io_handler(
  stop_action~ : () -> Unit,
  action~ : (Handler) -> Unit,
) -> Handler {
  Handler::make(stop_action~, action~)
}

///|
let counter : Ref[UInt64] = { val: 0UL }

///|
pub fn[A] T::on_ready(
  self : T[A],
  subscribe : A,
  action : (Handler) -> Unit,
  stop_action? : () -> Unit = fn() {  },
) -> Unit {
  counter.val += 1
  let id = counter.val
  self.add_handler(
    id,
    subscribe,
    make_io_handler(
      stop_action=fn() {
        self.remove_handler(id)
        stop_action()
      },
      action~,
    ),
  )
}

///|
pub async fn[A] T::sync(self : T[A], subscribe : A) -> Unit noraise {
  shift(fn(resume_) {
    self.on_ready(subscribe, fn(handler) {
      handler.stop()
      resume_(())
    })
  })
}

///|
pub fn[A : Sync] T::run_until(self : T[A], done : () -> Bool) -> Unit {
  while !done() {
    iter(self)
  }
}

///|
pub fn[A : Sync] T::run(self : T[A]) -> Unit {
  self.run_until(fn() { self.handlers.is_empty() })
}
