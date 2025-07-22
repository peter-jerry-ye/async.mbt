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
pub fn Handler::make(
  action~ : (Handler) -> Unit,
  stop_action~ : () -> Unit = fn() {  },
) -> Handler {
  Handler::{ stopped: false, stop_action, action }
}

///|
pub fn Handler::start(self : Handler) -> Unit {
  (self.action)(self)
}

///|
pub fn Handler::stop(self : Handler) -> Unit {
  self.stopped = true
  (self.stop_action)()
}

///|
pub fn Handler::is_stopped(self : Handler) -> Bool {
  self.stopped
}
