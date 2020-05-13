import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:corsac_jwt/corsac_jwt.dart';

import 'compute.dart';
import 'crypt.dart';
import 'database.dart';

/// Information on the user making the request.
extension AuthorizationInfo on Request {
  /// The username of the logged in user.
  ///
  /// If this is a non null value, the user was authenticated.
  String get username => this.attachments['username'];
  set username(String value) => this.attachments['username'] = value;

  /// Whether the user may create new resources.
  ///
  /// This can only be true if the user was authenticated.
  bool get mayUpload => this.attachments['mayUpload'] ?? false;
  set mayUpload(bool value) => this.attachments['mayUpload'] = value;

  /// Whether the user may edit existing resources.
  ///
  /// This can only be true if the user was authenticated.
  bool get mayEdit => this.attachments['mayEdit'] ?? false;
  set mayEdit(bool value) => this.attachments['mayEdit'] = value;

  /// Whether the user may delete resources.
  ///
  /// This can only be true if the user was authenticated.
  bool get mayDelete => this.attachments['mayDelete'] ?? false;
  set mayDelete(bool value) => this.attachments['mayDelete'] = value;
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

      final String username = json['username'];
      final String email = json['email'];
      final String password = json['password'];

      // Check if we already have a user with that name.
      final existingUser = await db.getUser(username);
      if (existingUser != null) {
        // Returning something different than 200 here has the security
        // implication that an attacker can check for existing user names. At
        // the moment, I don't see any alternatives, because we don't use email
        // addresses for identification. The client needs to know, whether the
        // user name is already given.
        return Response.conflict();
      } else {
        // This will take a long time, so we run it in a new isolate.
        final result = await compute(Crypt.hashPassword, password);

        db.updateUser(User(
          name: username,
          email: email,
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

      final String username = json['username'];
      final String password = json['password'];

      final user = await db.getUser(username);
      if (user != null) {
        // We check the password in a new isolate, because this can take a long
        // time.
        if (await compute(
          Crypt.checkPassword,
          CheckPasswordRequest(
            password: password,
            salt: user.salt,
            hash: user.hash,
          ),
        )) {
          final builder = JWTBuilder()
            ..expiresAt = DateTime.now().add(Duration(minutes: 30))
            ..setClaim('user', username);

          final token = builder.getSignedToken(_signer).toString();

          return Response.ok(token, headers: {'Content-Type': 'text/plain'});
        }
      }

      return Response.unauthorized();
    }

    return Response(HttpStatus.methodNotAllowed, null, null);
  }
}

/// An endpoint controller for retrieving and changing account details.
class AccountDetailsController extends Controller {
  final ServerDatabase db;

  AccountDetailsController(this.db);

  @override
  Future<Response> handle(Request request) async {
    if (request.method == 'GET') {
      if (request.username != null) {
        final user = await db.getUser(request.username);
        return Response.ok({
          'email': user.email,
        });
      } else {
        return Response.forbidden();
      }
    } else if (request.method == 'POST') {
      final json = await request.body.decode<Map<String, dynamic>>();

      final String username = json['username'];
      final String password = json['password'];
      final String newEmail = json['newEmail'];
      final String newPassword = json['newPassword'];

      final user = await db.getUser(username);

      // Check whether the user exists and the password was right.
      if (user != null &&
          await compute(
            Crypt.checkPassword,
            CheckPasswordRequest(
              password: password,
              salt: user.salt,
              hash: user.hash,
            ),
          )) {
        final hashResult = await compute(Crypt.hashPassword, newPassword);

        db.updateUser(User(
          name: username,
          email: newEmail,
          salt: hashResult.salt,
          hash: hashResult.hash,
          mayUpload: user.mayUpload,
          mayEdit: user.mayEdit,
          mayDelete: user.mayDelete,
        ));

        return Response.ok(null);
      } else {
        return Response.forbidden();
      }
    } else {
      return Response(HttpStatus.methodNotAllowed, null, null);
    }
  }
}

/// An endpoint controller for deleting an account.
class AccountDeleteController extends Controller {
  final ServerDatabase db;

  AccountDeleteController(this.db);

  @override
  Future<Response> handle(Request request) async {
    if (request.method == 'POST') {
      final json = await request.body.decode<Map<String, dynamic>>();

      final String username = json['username'];
      final String password = json['password'];

      final user = await db.getUser(username);

      // Check whether the user exists and the password was right.
      if (user != null &&
          await compute(
            Crypt.checkPassword,
            CheckPasswordRequest(
              password: password,
              salt: user.salt,
              hash: user.hash,
            ),
          )) {
        await db.deleteUser(username);

        return Response.ok(null);
      } else {
        return Response.forbidden();
      }
    } else {
      return Response(HttpStatus.methodNotAllowed, null, null);
    }
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
            request.username = user.name;
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
