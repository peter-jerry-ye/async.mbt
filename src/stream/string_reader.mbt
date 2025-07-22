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

///| A reader based on a string
pub struct StringReader {
  mut closed : Bool
  mut buffer : @string.View
}

///| Creates a new StringReader based on a string
pub fn string_reader(string : String) -> StringReader {
  { closed: false, buffer: string.view() }
}

///|
pub impl Closable for StringReader with close(self) {
  self.closed = true
}

///|
pub impl Reader for StringReader with read(self, builder, max_len~) {
  @promise.spawn(fn() {
    guard !self.closed else { fail("EOF") }
    if self.buffer is [] {
      return None
    } else {
      let index = self.buffer.offset_of_nth_char(max_len)
      if index is Some(index) {
        builder.write_substring(
          self.buffer.data(),
          self.buffer.start_offset(),
          index,
        )
        self.buffer = self.buffer.view(start_offset=index)
        Some(())
      } else {
        builder.write_substring(
          self.buffer.data(),
          self.buffer.start_offset(),
          self.buffer.length(),
        )
        self.buffer = "".view()
        Some(())
      }
    }
  })
}

///|
test "string reader" {
  @promise.spawn(fn() {
    try {
      let reader = string_reader("asdf")
      let builder = StringBuilder::new()
      guard reader.read(builder, max_len=0).await() is Some(_)
      inspect(builder, content="")
      guard reader.read(builder, max_len=2).await() is Some(_)
      inspect(builder, content="as")
      guard reader.read(builder, max_len=10).await() is Some(_)
      inspect(builder, content="asdf")
      guard reader.read(builder, max_len=10).await() is None
    } catch {
      InspectError(e) => {
        println(e)
        panic()
      }
      e => {
        println(e)
        panic()
      }
    }
  })
  |> ignore
}
