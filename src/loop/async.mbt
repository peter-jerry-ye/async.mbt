///|
async fn shift[A](f : ((A) -> Unit) -> Unit) -> A = "%async.suspend"

///|
pub fn reset(f : async () -> Unit) -> Unit = "%async.run"
