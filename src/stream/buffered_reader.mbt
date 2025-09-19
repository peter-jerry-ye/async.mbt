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
/// A reader that buffers the input stream and provides line reading capabilities.
struct BufferedReader {
  stream : &Reader
  mut buffer : @string.View
  mut error : Error?
}

///|
/// Create a buffered reader from a reader
pub fn buffered_reader(stream : &Reader) -> BufferedReader {
  { stream, buffer: "", error: None }
}

///|
pub impl Closable for BufferedReader with close(self) {
  self.stream.close()
  self.buffer = ""
}

///|
pub impl Reader for BufferedReader with read(self, builder, max_len?) {
  @promise.spawn(fn() {
    // if there were error not thrown, throw it
    if self.error is Some(error) {
      self.error = None
      raise error
    }
    if max_len is Some(len) && self.buffer.length() > len {
      builder.write_substring(
        self.buffer.data(),
        self.buffer.start_offset(),
        self.buffer.length(),
      )
      self.buffer = self.buffer.view(start_offset=len)
      return Some(())
    } else if self.buffer.length() > 0 {
      builder.write_substring(
        self.buffer.data(),
        self.buffer.start_offset(),
        self.buffer.length(),
      )
      self.buffer = "".view()
      return Some(())
    } else {
      self.stream.read(builder, max_len?).await()
    }
  })
}

///|
pub fn BufferedReader::next_line(self : BufferedReader) -> @promise.T[String?] {
  @promise.spawn(async fn() {
    let builder = StringBuilder::new()
    self.read_line(builder).await().map(_ => builder.to_string())
  })
}

///|
pub fn BufferedReader::read_line(
  self : BufferedReader,
  builder : StringBuilder,
) -> @promise.T[Unit?] {
  @promise.spawn(async fn() {
    if self.error is Some(e) {
      self.error = None
      raise e
    }
    if split_line(self.buffer) is Some((line, rest)) {
      builder.write_substring(line.data(), line.start_offset(), line.length())
      self.buffer = rest
      return Some(())
    }
    let mut length = self.buffer.length()
    builder.write_substring(
      self.buffer.data(),
      self.buffer.start_offset(),
      self.buffer.length(),
    )
    let buffer = StringBuilder::new()
    while self.stream.read(buffer, max_len=1024).await() is Some(_) {
      let str = buffer.to_string()
      if split_line(str.view()) is Some((line, rest)) {
        builder.write_substring(line.data(), line.start_offset(), line.length())
        self.buffer = rest
        length += line.length()
        break
      } else {
        length += str.length()
        builder.write_string(str)
        buffer.reset()
      }
    }
    if length > 0 {
      Some(())
    } else {
      None
    }
  })
}

///|
fn split_line(str : @string.View) -> (@string.View, @string.View)? {
  let input = str
  loop str {
    ['\n', .. rest] => {
      let before = input.view(
        end_offset=rest.start_offset() - input.start_offset() - 1,
      )
      if before is [.. before, '\r'] {
        return Some((before, rest))
      } else {
        return Some((before, rest))
      }
    }
    [_, .. rest] => continue rest
    [] => return None
  }
}

///|
test "split line" {
  let str = "Hello, world!\nThis is a test.\r\nAnother line."
  let (line, rest) = split_line(str[:]).unwrap()
  inspect(line, content="Hello, world!")
  inspect(rest, content="This is a test.\r\nAnother line.")
  let (line, rest) = split_line(str[14:]).unwrap()
  inspect(line, content="This is a test.")
  inspect(rest, content="Another line.")
  let (line, rest) = split_line(str[30:]).unwrap()
  inspect(line, content="")
  inspect(rest, content="Another line.")
  inspect(split_line(str[31:]), content="None")
}

///|
test "next line" {
  @promise.spawn(async fn() noraise {
    try {
      let str = "Hello, world!\nThis is a test.\r\nAnother line."
      let reader = buffered_reader(string_reader(str))
      inspect(reader.next_line().await().unwrap(), content="Hello, world!")
      inspect(reader.next_line().await().unwrap(), content="This is a test.")
      inspect(reader.next_line().await().unwrap(), content="Another line.")
    } catch {
      e => {
        println(e)
        panic()
      }
    }
  })
  |> ignore
}
