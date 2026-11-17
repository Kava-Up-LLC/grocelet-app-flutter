/// What can go wrong, in the words the UI needs.
enum FailureKind { noConnection, houseNotFound, unexpected }

class AppFailure implements Exception {
  const AppFailure(this.kind, [this.cause]);

  final FailureKind kind;
  final Object? cause;

  /// The banner text for failures shown on the list and forms.
  String get message => switch (kind) {
        FailureKind.noConnection => "No connection. Changes can't be saved right now.",
        FailureKind.houseNotFound => 'No house with that code. Check the 6 letters with whoever created it.',
        FailureKind.unexpected => 'Something went wrong. Try again.',
      };

  @override
  String toString() => 'AppFailure($kind, $cause)';
}
