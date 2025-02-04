// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:curt/src/curt_http_headers.dart';
import 'package:curt/src/curt_response.dart';

///
///
///
class Curt {
  final String executable;
  final bool debug;
  final bool insecure;
  final bool silent;
  final bool followRedirects;
  final int timeout;

  ///
  ///
  ///
  Curt({
    this.executable = 'curl',
    this.debug = false,
    this.insecure = false,
    this.silent = true,
    this.followRedirects = false,
    this.timeout = 10000,
  });

  ///
  ///
  ///
  Future<CurtResponse> send(
    Uri uri, {
    required String method,
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
    String? data,
  }) async {
    final List<String> args = <String>['-v', '-X', method];

    /// Insecure
    if (insecure) {
      args.add('-k');
    }

    /// Silent
    if (silent) {
      args.add('-s');
    }

    /// Follow Redirects
    if (followRedirects) {
      args.add('-L');
    }

    /// Headers
    for (final MapEntry<String, String> header in headers.entries) {
      args
        ..add('-H')
        ..add('${header.key}: ${header.value}');
    }

    /// Cookies
    for (final Cookie cookie in cookies) {
      args
        ..add('--cookie')
        ..add('${cookie.name}=${cookie.value}');
    }

    /// Body data
    if (data != null) {
      args
        ..add('-d')
        ..add(data);
    }

    /// URL
    args.add(uri.toString());

    if (debug) {
      print('$executable ${args.join(' ')}');
    }

    ///
    /// Run
    ///
    final ProcessResult run = await Process.run(executable, args).timeout(
      Duration(
        milliseconds: timeout,
      ),
    );

    if (run.exitCode != 0) {
      if (debug) {
        print('Exit Code: ${run.exitCode}');
        print(run.stdout);
        print(run.stderr);
      }
      throw Exception('Error: ${run.exitCode} - ${run.stderr}');
    }

    ///
    /// Parse
    ///
    final List<String> verboseLines = run.stderr.toString().split('\n');

    final RegExp headerRegExp = RegExp('(?<key>.*?): (?<value>.*)');

    final RegExp protocolRegExp = RegExp(r'HTTP(.*?) (?<statusCode>\d*)');

    int statusCode = -1;

    final CurtHttpHeaders responseHeaders = CurtHttpHeaders();

    for (final String verboseLine in verboseLines) {
      if (debug) {
        print(verboseLine);
      }

      if (verboseLine.isEmpty) {
        continue;
      }

      if (verboseLine.substring(0, 1) == '<') {
        final String line = verboseLine.substring(2);

        RegExpMatch? match = headerRegExp.firstMatch(line);
        if (match != null) {
          responseHeaders.add(
            match.namedGroup('key').toString(),
            match.namedGroup('value').toString(),
          );
          continue;
        }

        match = protocolRegExp.firstMatch(line);
        if (match != null) {
          statusCode =
              int.tryParse(match.namedGroup('statusCode').toString()) ?? -1;
          responseHeaders.clear();
        }
      }
    }

    return CurtResponse(
      run.stdout.toString(),
      statusCode,
      headers: responseHeaders,
    );
  }

  ///
  ///
  ///
  Future<CurtResponse> sendJson(
    Uri uri, {
    required String method,
    required Map<String, dynamic> body,
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
    String contentType = 'application/json',
  }) {
    final Map<String, String> newHeaders = Map<String, String>.of(headers);
    newHeaders['Content-Type'] = contentType;

    return send(
      uri,
      method: method,
      headers: newHeaders,
      cookies: cookies,
      data: json.encode(body),
    );
  }

  ///
  ///
  ///
  Future<CurtResponse> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
  }) =>
      send(uri, method: 'GET', headers: headers, cookies: cookies);

  ///
  ///
  ///
  Future<CurtResponse> post(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
    String? data,
  }) =>
      send(uri, method: 'POST', headers: headers, data: data, cookies: cookies);

  ///
  ///
  ///
  Future<CurtResponse> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
    String contentType = 'application/json',
  }) =>
      sendJson(
        uri,
        method: 'POST',
        headers: headers,
        body: body,
        cookies: cookies,
        contentType: contentType,
      );

  ///
  ///
  ///
  Future<CurtResponse> put(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
    String? data,
  }) =>
      send(uri, method: 'PUT', headers: headers, data: data, cookies: cookies);

  ///
  ///
  ///
  Future<CurtResponse> putJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
    String contentType = 'application/json',
  }) =>
      sendJson(
        uri,
        method: 'PUT',
        headers: headers,
        body: body,
        cookies: cookies,
        contentType: contentType,
      );

  ///
  ///
  ///
  Future<CurtResponse> delete(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    List<Cookie> cookies = const <Cookie>[],
  }) =>
      send(uri, method: 'DELETE', headers: headers, cookies: cookies);
}
