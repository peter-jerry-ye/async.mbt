///|
/// Types that can be synced.
/// 
/// It should be able to sync an array of itself 
/// and return the indices of finished items.
pub(open) trait Sync {
  sync(Array[Self]) -> FixedArray[UInt]
}

///|
struct T[A] {
  handlers : Map[UInt64, (A, Handler)]
}

///|
struct Handler {
  mut stopped : Bool
  stop_action : () -> Unit
  action : (Handler) -> Unit
}
