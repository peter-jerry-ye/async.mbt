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
pub(open) trait Closable {
  close(Self) -> Unit
}

///|
pub(open) trait Flushable {
  flush(Self) -> @promise.T[Unit]
}

///| 
/// This trait represents an interface that provides the ability for low level async read operations.
/// 
/// The `Self` here may represent a stream / file descriptor, or a stream / file descriptor + event loop.
pub(open) trait InputStream: Closable {
  read(Self, FixedArray[Byte], offset~ : Int, max_len~ : Int) -> @promise.T[
    Int?,
  ]
}

///| 
/// This trait represents an interface that provides the ability for low level async write operations.
/// 
/// The `Self` here may represent a stream / file descriptor, or a stream / file descriptor + event loop.
pub(open) trait OutputStream: Closable + Flushable {
  write(Self, @bytes.View) -> @promise.T[Unit]
}

///| 
/// This trait represents an interface that provides the ability for async read operations based on Chars.
/// 
/// The `Self` here may represent a stream / file descriptor, or a stream / file descriptor + event loop.
pub(open) trait Reader: Closable {
  read(Self, StringBuilder, max_len~ : Int) -> @promise.T[Unit?]
}

///| 
/// This trait represents an interface that provides the ability for async write operations based on Chars.
/// 
/// The `Self` here may represent a stream / file descriptor, or a stream / file descriptor + event loop.
pub(open) trait Writer: Closable + Flushable {
  write(Self, @string.View) -> @promise.T[Unit]
}

///|
pub(all) type AsyncIterable[T] async () -> T raise
