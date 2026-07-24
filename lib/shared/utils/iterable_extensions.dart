/// Extensions on [Iterable] for safe element retrieval.
extension IterableNullSafetyExtension<E> on Iterable<E> {
  /// Returns the first element of this iterable, or `null` if the iterable is empty.
  E? get firstOrNull => isEmpty ? null : first;
}
