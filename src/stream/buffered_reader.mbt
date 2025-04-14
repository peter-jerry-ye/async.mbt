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

///| A reader that buffers the input stream and provides line reading capabilities.
pub struct BufferedReader {
  stream : &Reader
  mut buffer : String
  mut offset : UInt
  mut len : UInt
}

///| Create a buffered reader from a reader
pub fn buffered_reader(stream : &Reader) -> BufferedReader {
  { stream, buffer: "", offset: 0, len: 0 }
}

///|
pub impl Closable for BufferedReader with closed(self) {
  self.stream.closed() && self.len == 0
}

///|
pub impl Closable for BufferedReader with close(self) {
  self.stream.close()
  self.buffer = ""
  self.offset = 0
  self.len = 0
}

///|
pub impl Reader for BufferedReader with readable(self) {
  self.stream.readable() || self.len > 0
}

///|
pub impl Reader for BufferedReader with read(self, size) {
  @promise.spawn(async fn(_defer) {
    // Only handles requests within uint
    let size = size.to_uint()
    let builder = StringBuilder::new()
    if self.len > size {
      builder.write_substring(
        self.buffer,
        self.offset.reinterpret_as_int(),
        size.reinterpret_as_int(),
      )
      self.offset += size
      self.len -= size
    } else if self.len > 0 {
      builder.write_substring(
        self.buffer,
        self.offset.reinterpret_as_int(),
        self.len.reinterpret_as_int(),
      )
      self.buffer = ""
      self.offset = 0
      self.len = 0
    }
    if self.stream.readable() {
      builder.write_string(
        self.stream.read((size - self.len).to_uint64()).await!!(),
      )
    }
    builder.to_string()
  })
}

///|
pub fn BufferedReader::read_line(self : BufferedReader) -> @promise.T[String] {
  @promise.spawn(async fn(_defer) {
    let result = StringBuilder::new()
    if split_line(self.buffer, self.offset) is Some((line, rest)) {
      self.buffer = rest
      self.offset = 0
      self.len = rest.length().reinterpret_as_uint()
      return line
    } else {
      result.write_substring(
        self.buffer,
        self.offset.reinterpret_as_int(),
        self.len.reinterpret_as_int(),
      )
    }
    while self.readable() {
      let next_str = self.stream.read(1024).await!!()
      if split_line(next_str, 0) is Some((line, rest)) {
        result.write_string(line)
        self.buffer = rest
        self.offset = 0
        self.len = rest.length().reinterpret_as_uint()
        return result.to_string()
      } else {
        result.write_string(next_str)
      }
    }
    result.to_string()
  })
}

///|
fn split_line(str : String, start_offset : UInt) -> (String, String)? {
  let mut index = start_offset.reinterpret_as_int()
  for ch in str.view(start_offset=start_offset.reinterpret_as_int()) {
    if ch == '\n' {
      let line = str.substring(
        start=start_offset.reinterpret_as_int(),
        end=index,
      )
      let rest = str.substring(start=index + 1)
      break Some((line, rest))
    } else if ch == '\r' {
      // Check if the next character is '\n'
      let next_index = index + 1
      if next_index < str.length() && str.char_at(next_index) == '\n' {
        let line = str.substring(
          start=start_offset.reinterpret_as_int(),
          end=index,
        )
        let rest = str.substring(start=index + 2)
        break Some((line, rest))
      } else {
        let line = str.substring(
          start=start_offset.reinterpret_as_int(),
          end=index,
        )
        let rest = str.substring(start=index + 1)
        break Some((line, rest))
      }
    }
    // Handle surrogate pairs
    if ch.to_int() < 0x10000 {
      index += 1
    } else {
      index += 2
    }
  } else {
    None
  }
}

///|
test "split line" {
  let str = "Hello, world!\nThis is a test.\r\nAnother line."
  let (line, rest) = split_line(str, 0).unwrap()
  inspect!(line, content="Hello, world!")
  inspect!(rest, content="This is a test.\r\nAnother line.")
  let (line, rest) = split_line(str, 14).unwrap()
  inspect!(line, content="This is a test.")
  inspect!(rest, content="Another line.")
  let (line, rest) = split_line(str, 30).unwrap()
  inspect!(line, content="")
  inspect!(rest, content="Another line.")
  inspect!(split_line(str, 31), content="None")
}
