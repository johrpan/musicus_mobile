import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:corsac_jwt/corsac_jwt.dart';

import 'compute.dart';
import 'crypt.dart';
import 'database.dart';

/// Information on the rights of the user making the request.
extension AuthorizationInfo on Request {
  /// Whether the user may create new resources.
  set mayUpload(bool value) => this.attachments['mayUpload'] = value;
  bool get mayUpload => this.attachments['mayUpload'] ?? false;

  /// Whether the user may edit existing resources.
  set mayEdit(bool value) => this.attachments['mayEdit'] = value;
  bool get mayEdit => this.attachments['mayEdit'] ?? false;

  /// Whether the user may delete resources.
  set mayDelete(bool value) => this.attachments['mayDelete'] = value;
  bool get mayDelete => this.attachments['mayDelete'] ?? false;
}

/// A user as presented within a request.
class RequestUser {
  /// The unique user name.
  final String name;

  /// An optional email address.
  final String email;

  /// The password in clear text.
  final String password;

  RequestUser({
    this.name,
    this.email,
    this.password,
  });

  factory RequestUser.fromJson(Map<String, dynamic> json) => RequestUser(
        name: json['name'],
        email: json['email'],
        password: json['password'],
      );
}

/// Endpoint controller for user registration.
///
/// This expects a POST request with a JSON body representing a [RequestUser].
class RegisterController extends Controller {
  final ServerDatabase db;

  RegisterController(this.db);

  @override
  Future<Response> handle(Request request) async {
    if (request.method == 'POST') {
      final json = await request.body.decode<Map<String, dynamic>>();
      final requestUser = RequestUser.fromJson(json);

      // Check if we already have a user with that name.
      final existingUser = await db.getUser(requestUser.name);
      if (existingUser != null) {
        // Returning something different than 200 here has the security
        // implication that an attacker can check for existing user names. At
        // the moment, I don't see any alternatives, because we don't use email
        // addresses for identification. The client needs to know, whether the
        // user name is already given.
        return Response.conflict();
      } else {
        // This will take a long time, so we run it in a new isolate.
        final result = await compute(Crypt.hashPassword, requestUser.password);

        db.updateUser(User(
          name: requestUser.name,
          email: requestUser.email,
          salt: result.salt,
          hash: result.hash,
          mayUpload: true,
          mayEdit: false,
          mayDelete: false,
        ));

        return Response.ok(null);
      }
    } else {
      return Response(HttpStatus.methodNotAllowed, null, null);
    }
  }
}

/// Endpoint controller for user login.
///
/// This expects a POST request with a JSON body representing a [RequestUser].
class LoginController extends Controller {
  final ServerDatabase db;

  /// The secret that will be used for signing the token.
  final String secret;

  final JWTHmacSha256Signer _signer;

  LoginController(this.db, this.secret) : _signer = JWTHmacSha256Signer(secret);

  @override
  Future<Response> handle(Request request) async {
    if (request.method == 'POST') {
      final json = await request.body.decode<Map<String, dynamic>>();
      final requestUser = RequestUser.fromJson(json);

      final realUser = await db.getUser(requestUser.name);
      if (realUser != null) {
        // We check the password in a new isolate, because this can take a long
        // time.
        if (await compute(
          Crypt.checkPassword,
          CheckPasswordRequest(
            password: requestUser.password,
            salt: realUser.salt,
            hash: realUser.hash,
          ),
        )) {
          final builder = JWTBuilder()
            ..expiresAt = DateTime.now().add(Duration(minutes: 30))
            ..setClaim('user', requestUser.name);

          final token = builder.getSignedToken(_signer).toString();

          return Response.ok(token, headers: {'Content-Type': 'text/plain'});
        }
      }

      return Response.unauthorized();
    }

    return Response(HttpStatus.methodNotAllowed, null, null);
  }
}

/// Middleware for checking authorization.
///
/// This will set the fields defined in [AuthorizationInfo] on this request
/// according to the provided access token.
class AuthorizationController extends Controller {
  final ServerDatabase db;

  /// The secret that was used to sign the token.
  final String secret;

  final JWTHmacSha256Signer _signer;

  AuthorizationController(this.db, this.secret)
      : _signer = JWTHmacSha256Signer(secret);

  @override
  FutureOr<RequestOrResponse> handle(Request request) async {
    final authHeaderValue =
        request.raw.headers.value(HttpHeaders.authorizationHeader);

    if (authHeaderValue != null) {
      final authHeaderParts = authHeaderValue.split(' ');

      if (authHeaderParts.length == 2 && authHeaderParts[0] == 'Bearer') {
        final jwt = JWT.parse(authHeaderParts[1]);

        /// The JWTValidator will automatically use the current time. An empty
        /// result will mean that the token is valid and its signature was
        /// verified.
        if (JWTValidator().validate(jwt, signer: _signer).isEmpty) {
          final user = await db.getUser(jwt.claims['user']);
          if (user != null) {
            request.mayUpload = user.mayUpload;
            request.mayEdit = user.mayEdit;
            request.mayDelete = user.mayDelete;

            return request;
          } else {
            return Response.unauthorized();
          }
        } else {
          return Response.unauthorized();
        }
      } else {
        return Response.badRequest();
      }
    } else {
      return request;
    }
  }
}
