import 'dart:math';

/// Extension to provide Fisher-Yates shuffle algorithm for List.
/// This ensures fair randomization of elements, suitable for shuffling questions in an exam.
extension FisherYatesShuffle<T> on List<T> {
  void fisherYatesShuffle({Random? random}) {
    random ??= Random();
    for (var i = length - 1; i > 0; i--) {
      var j = random.nextInt(i + 1);
      var temp = this[i];
      this[i] = this[j];
      this[j] = temp;
    }
  }
}
