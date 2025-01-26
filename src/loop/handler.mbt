///|
pub fn Handler::make(
  action~ : (Handler) -> Unit,
  stop_action~ : () -> Unit = fn() {  }
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
