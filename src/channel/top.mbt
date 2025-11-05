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
struct Channel[A] {
  buffer : @queue.Queue[A]
  capacity : UInt
  producers : @queue.Queue[(A, (Unit) -> Unit)]
  consumers : @queue.Queue[(A) -> Unit]
}

///|
pub fn[A] make(size? : UInt = 1) -> Channel[A] {
  {
    buffer: @queue.new(),
    capacity: size,
    producers: @queue.new(),
    consumers: @queue.new(),
  }
}

///|
pub async fn[A] Channel::push(self : Channel[A], value : A) -> Unit noraise {
  if self.capacity > self.buffer.length().reinterpret_as_uint() {
    match self.consumers.pop() {
      Some(consumer) => consumer(value)
      None => self.buffer.push(value)
    }
  } else {
    shift(fn(k) { self.producers.push((value, k)) })
  }
}

///|
pub async fn[A] Channel::pop(self : Channel[A]) -> A noraise {
  match self.buffer.pop() {
    Some(value) => {
      match self.producers.pop() {
        Some((new_value, k)) => {
          self.buffer.push(new_value)
          k(())
        }
        None => ()
      }
      value
    }
    None => shift(fn(k) { self.consumers.push(k) })
  }
}

///|
async fn[A] shift(f : ((A) -> Unit) -> Unit) -> A noraise = "%async.suspend"
