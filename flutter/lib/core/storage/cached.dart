/// A value read from Supabase, or from the on-device copy of the last
/// successful read when the server could not be reached.
class Cached<T> {
  const Cached(this.value, {this.fromCache = false});

  final T value;

  /// True when [value] is the offline copy (read-only until back online).
  final bool fromCache;
}
