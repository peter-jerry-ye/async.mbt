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
priv struct OutputStreamWriter[T] {
  stream : T
  encoding : @encoding.Encoding
}

///|
impl[T : Closable] Closable for OutputStreamWriter[T] with closed(self) {
  self.stream.closed()
}

///|
impl[T : Closable] Closable for OutputStreamWriter[T] with close(self) {
  self.stream.close()
}

///|
impl[T : OutputStream] Writer for OutputStreamWriter[T] with writable(self) {
  self.stream.writable()
}

///|
impl[T : OutputStream] Writer for OutputStreamWriter[T] with write(self, string) {
  self.stream.write(@encoding.encode(string, encoding=self.encoding))
}

///|
impl[T : OutputStream] Flushable for OutputStreamWriter[T] with flush(self) {
  self.stream.flush()
}

///| Create a writer from an output stream through the given encoding.
pub fn[T : OutputStream] output_stream_writer(
  stream : T,
  encoding~ : @encoding.Encoding = UTF8
) -> &Writer {
  ({ stream, encoding } : OutputStreamWriter[T]) as &Writer
}
