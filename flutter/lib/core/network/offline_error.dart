import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// True when [error] means "could not reach the server" (no signal, DNS,
/// TLS handshake, timeout), as opposed to the server rejecting the request.
bool isOfflineError(Object error) =>
    error is SocketException ||
    error is TimeoutException ||
    error is HandshakeException ||
    error is http.ClientException ||
    error is AuthRetryableFetchException;
