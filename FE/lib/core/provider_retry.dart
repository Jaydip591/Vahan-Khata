/// Riverpod 3 retries failed providers in the background by default, which would
/// leave the user looking at a spinner when the network is down. We show the error
/// with a retry button instead.
Duration? noAutoRetry(int retryCount, Object error) => null;
