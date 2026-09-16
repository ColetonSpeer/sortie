/// Minimal Result type for operations that fail in expected ways.
sealed class Result<T> {
  const Result();
  bool get isOk => this is Ok<T>;
  T get value => (this as Ok<T>).value;
  Object get error => (this as Err<T>).error;

  R when<R>({required R Function(T) ok, required R Function(Object, StackTrace?) err}) =>
      switch (this) {
        Ok<T>(value: final v) => ok(v),
        Err<T>(error: final e, stackTrace: final s) => err(e, s),
      };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  @override
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error, [this.stackTrace]);
  @override
  final Object error;
  final StackTrace? stackTrace;
}
