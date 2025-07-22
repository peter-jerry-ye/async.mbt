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
  buffer : FixedArray[Byte]
  decoder : @encoding.Decoder
}

///|
impl[T : Closable] Closable for InputStreamReader[T] with close(self) {
  self.stream.close()
}

///|
impl[T : InputStream] Reader for InputStreamReader[T] with read(
  self,
  builder,
  max_len~,
) {
  @promise.spawn(async fn() raise {
    let bytes = self.stream
      .read(self.buffer, offset=0, max_len=max_len * 2)
      .await()
    guard bytes is Some(read_len) else {
      return if self.decoder.decode("", stream=false) is output && output != "" {
        builder.write_string(output)
        Some(())
      } else {
        None
      }
    }
    let input = self.buffer.unsafe_reinterpret_as_bytes()[:read_len]
    builder.write_string(self.decoder.decode(input, stream=true))
    Some(())
  })
}

///| Create a reader from an input stream through the given encoding.
pub fn[T : InputStream] input_stream_reader(
  stream : T,
  encoding~ : @encoding.Encoding = UTF8,
  buffer_size~ : Int = 4096,
) -> &Reader {
  (
    {
      stream,
      buffer: FixedArray::make(buffer_size, b'\x00'),
      decoder: @encoding.decoder(encoding),
    } : InputStreamReader[T])
  as &Reader
}
