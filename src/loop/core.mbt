///|
pub fn new[A : Sync]() -> T[A] {
  { handlers: Map::new() }
}

///|
fn add_handler[A : Sync](
  self : T[A],
  id : UInt64,
  subscribe : A,
  action : Handler
) -> Unit {
  self.handlers[id] = (subscribe, action)
}

///|
fn remove_handler[A](self : T[A], id : UInt64) -> Unit {
  self.handlers.remove(id)
}

///|
fn iter[A : Sync](engine : T[A]) -> Unit {
  let values = engine.handlers.values().collect()
  let wait = values.map(fn(pair) { pair.0 })
  let result = A::sync(wait)
  result.each(fn(id) {
    let handle = values[id.reinterpret_as_int()].1
    if not(handle.is_stopped()) {
      values[id.reinterpret_as_int()].1.start()
    }
  })
}

///|
fn make_io_handler(
  stop_action~ : () -> Unit,
  action~ : (Handler) -> Unit
) -> Handler {
  Handler::make(stop_action~, action~)
}

///|
let counter : Ref[UInt64] = { val: 0UL }

///|
pub fn on_ready[A : Sync](
  self : T[A],
  subscribe : A,
  action : (Handler) -> Unit,
  stop_action~ : () -> Unit = fn() {  }
) -> Unit {
  counter.val += 1
  let id = counter.val
  self.add_handler(
    id,
    subscribe,
    make_io_handler(
      stop_action=fn() {
        self.remove_handler(id)
        stop_action()
      },
      action~,
    ),
  )
}

///|
pub async fn sync[A : Sync](self : T[A], subscribe : A) -> Unit {
  shift!!(fn(resume) {
    self.on_ready(subscribe, fn(handler) {
      handler.stop()
      resume(())
    })
  })
}

///|
pub fn run_until[A : Sync](self : T[A], done : () -> Bool) -> Unit {
  while not(done()) {
    iter(self)
  }
}

///|
pub fn run[A : Sync](self : T[A]) -> Unit {
  run_until(self, fn() { self.handlers.is_empty() })
}
