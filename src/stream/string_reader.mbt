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
pub impl Closable for StringReader with closed(self) {
  self.closed
}

///|
pub impl Closable for StringReader with close(self) {
  self.closed = true
}

///|
pub impl Reader for StringReader with readable(self) {
  not(self.closed)
}

///|
pub impl Reader for StringReader with read(self, ulen) {
  @promise.spawn(async fn(_defer) {
    if self.buffer is [] {
      fail!("EOF")
    } else {
      let index = self.buffer.offset_of_nth_char(ulen.to_int())
      if index is Some(index) {
        let result = self.buffer.view(end_offset=index).to_string()
        self.buffer = self.buffer.view(start_offset=index)
        result
      } else {
        let result = self.buffer.to_string()
        self.buffer = "".view()
        result
      }
    }
  })
}

///|
test "string reader" {
  @promise.spawn(async fn(_defer) {
    try {
      let reader = string_reader("asdf")
      inspect!(reader.read(0).await!(), content="")
      inspect!(reader.read(2).await!(), content="as")
      inspect!(reader.read(10).await!(), content="df")
      inspect!(
        try {
          reader.read(10).await!()
        } catch! {
          Failure(_) => "fail"
        },
        content="fail",
      )
    } catch {
      e => {
        println(e)
        panic()
      }
    }
  })
  |> ignore
}
