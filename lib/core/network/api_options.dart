// lib/core/network/api_options.dart
import 'package:dio/dio.dart';

enum RequestPriority { low, normal, high }

class ApiOptions {
  /// HTTP headers
  final Map<String, dynamic>? headers;

  /// Request content-type
  final String? contentType;

  /// Response type
  final ResponseType? responseType;

  /// Request timeout settings
  final Duration? connectTimeout;
  final Duration? receiveTimeout;
  final Duration? sendTimeout;

  /// Whether to follow redirects
  final bool? followRedirects;
  final int? maxRedirects;

  /// Retry configuration
  final int? maxRetries;
  final Duration? retryInterval;

  /// Cache configuration
  final Duration? cacheMaxAge;
  final bool? forceRefresh;

  /// Request priority
  final RequestPriority priority;

  const ApiOptions({
    this.headers,
    this.contentType,
    this.responseType,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.maxRetries,
    this.retryInterval,
    this.cacheMaxAge,
    this.forceRefresh = false,
    this.priority = RequestPriority.normal,
  });

  Options toDioOptions() {
    return Options(
      headers: headers,
      contentType: contentType,
      responseType: responseType,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      extra: {
        'maxRetries': maxRetries,
        'retryInterval': retryInterval,
        'cacheMaxAge': cacheMaxAge,
        'forceRefresh': forceRefresh,
        'priority': priority,
      },
    );
  }

  ApiOptions copyWith({
    Map<String, dynamic>? headers,
    String? contentType,
    ResponseType? responseType,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool? followRedirects,
    int? maxRedirects,
    int? maxRetries,
    Duration? retryInterval,
    Duration? cacheMaxAge,
    bool? forceRefresh,
    RequestPriority? priority,
  }) {
    return ApiOptions(
      headers: headers ?? this.headers,
      contentType: contentType ?? this.contentType,
      responseType: responseType ?? this.responseType,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      maxRetries: maxRetries ?? this.maxRetries,
      retryInterval: retryInterval ?? this.retryInterval,
      cacheMaxAge: cacheMaxAge ?? this.cacheMaxAge,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      priority: priority ?? this.priority,
    );
  }
}