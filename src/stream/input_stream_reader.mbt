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
priv struct InputStreamReader[T] {
  stream : T
  decoder : @encoding.Decoder
}

///|
impl[T : Closable] Closable for InputStreamReader[T] with closed(self) {
  self.stream.closed()
}

///|
impl[T : Closable] Closable for InputStreamReader[T] with close(self) {
  self.stream.close()
}

///|
impl[T : InputStream] Reader for InputStreamReader[T] with readable(self) {
  self.stream.readable()
}

///|
impl[T : InputStream] Reader for InputStreamReader[T] with read(self, size) {
  @promise.spawn(async fn(_defer) {
    let bytes = self.stream.read(size).await!()
    self.decoder.decode!(bytes, stream=not(self.stream.closed()))
  })
}

///| Create a reader from an input stream through the given encoding.
pub fn input_stream_reader[T : InputStream](
  stream : T,
  encoding~ : @encoding.Encoding = UTF8
) -> &Reader {
  ({ stream, decoder: @encoding.decoder(encoding) } : InputStreamReader[T])
  as &Reader
}
