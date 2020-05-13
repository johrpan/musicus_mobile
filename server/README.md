# Musicus server

A server hosting a shared Musicus database.

## Introduction

A Musicus server publishes the contents of a Musicus database via a simple
HTTP API. Registered users may additionally add entities to the database and
some users maintain the database by editing or deleting entities.

## API documentation

Important note: The Musicus API is not stable yet. This means, that there will
probably be breaking changes without any kind of versioning. At the moment,
this documentation while mostly describing the API as it works today is
nothing more than a draft.

### Retrieving information

All entities are available to the public without authentication. The response
will have the content type `application/json` and the body will contain either
a list of JSON objects or just a JSON object. The server handles `GET` requests
at the following routes:

| Route                    | Result                                          | Pagination | Search |
| ------------------------ | ----------------------------------------------- | ---------- | ------ |
| `/persons`               | A list of persons                               | Yes        | Yes    |
| `/persons/{id}`          | One person by its ID or error `404`             | No         | No     |
| `/persons/{id}/works`    | A list of works by the person or error `404`    | Yes        | Yes    |
| `/instruments`           | A list of instruments                           | Yes        | Yes    |
| `/instruments/{id}`      | One instrument by its ID or error `404`         | No         | No     |
| `/works/{id}`            | One work by its ID or error `404`               | No         | No     |
| `/works/{id}/recordings` | A list of recordings of the work or error `404` | Yes        | No     |
| `/ensembles`             | A list of ensembles                             | Yes        | Yes    |
| `/ensembles/{id}`        | One ensemble by its ID or error `404`           | No         | No     |
| `/recordings/{id}`       | One recording by its ID or error `404`          | No         | No     |

#### Pagination

Routes that use pagination for their result will always limit the result to a
constant amount of entities. You can get other pages using the `?p={page}`
query parameter.

#### Search

Routes supporting search can be supplied with a search string using the
`?s={search}` query parameter.

### Authentication

Users that would like to contribute to the information hosted by the server
will need to authenticate.

#### Registration

For registration, the server handles `POST` requests to `/account/register`.
The request body has to be valid JSON and have the following form.

```json
{
    "username": "username",
    "email": "optional@email.address",
    "password": "password"
}
```

The following errors may occur:

| Error code | Explanation                              |
| ---------- | ---------------------------------------- |
| `400`      | The body was malformed.                  |
| `409`      | The username is already taken.           |
| `415`      | Content type was not `application/json`. |

#### Login

All protected resources will check for a valid token within the authorization
header of the request. The client can get a token by sending a `POST` request
to `/account/login`. The request body should contain a valid JSON object of the
following form:

```json
{
    "username": "username",
    "password": "password"
}
```

If the operation was successful, the token will be returned in the response
body as a single string with the content type `text/plain`.

The following errors may occur:

| Error code | Explanation                              |
| ---------- | ---------------------------------------- |
| `400`      | The body was malformed.                  |
| `401`      | Login failed                             |
| `415`      | Content type was not `application/json`. |

#### Authorization

When accessing a protected resource, the client should include a authorization
header with the token retrieved when logging in. The authorization type should
be `Bearer`. If the provided token is valid and the user is authorized to
perform the requested action, the expected response for the route beeing
accessed will be returned.

The following errors may occur:

| Error code | Explanation                                              |
| ---------- | -------------------------------------------------------- |
| `400`      | The authorization header was malformed.                  |
| `401`      | The provided token is invalid.                           |
| `403`      | The user is not allowed to perform the requested action. |

#### Retrieving account details

The client can retrieve the current account details for a user using a `GET`
request to `/account/details`. The user has to be logged in. The returned body
will have the content type `application/json` and the following format:

```json
{
    "email": "optional@email.address"
}
```

#### Changing account details

To change the email address or password for an existing user, the client may
send a `POST` request to `/account/details`. The content type has to be
`application/json` and the body should contain a valid JSON object in the
following form:

```json
{
    "username": "username",
    "password": "old password",
    "newEmail": "optional@email.address",
    "newPassword": "new password"
}
```

The `newEmail` and `newPassword` parameters both can be left out or set to null
to indicate that they remain unchanged. `username` and `password` have to be
provided. If the user doesn't exist or the old password was wrong, an error
`403` will be returned.

#### Deleting an account

To delete an existing account, the client may send a `POST` request to
`/account/delete`. The content type has to be `application/json` and the body
should contain a valid JSON object in the following form:

```json
{
    "username": "username",
    "password": "password"
}
```

If the user doesn't exist or the password was wrong, an error `403` will be
returned.

### Adding new entities

To be able to add new entities, the user has to be authenticated and authorized
to do so. By default, this is the case for newly registered users. The content
type should be `application/json` and the body should contain a valid JSON
object matching the specific resource. The entity ID should be generated on
the client side to facilitate offline usage. This means, that entity creation
will be handled using `PUT` requests to the following routes:

- `/persons/{id}`
- `/instruments/{id}`
- `/works/{id}`
- `/ensembles/{id}`
- `/recordings/{id}`

The following errors may occur:

| Error code | Explanation                              |
| ---------- | ---------------------------------------- |
| `400`      | The body was malformed.                  |
| `415`      | Content type was not `application/json`. |


### Editing existing entities

To be able to edit existing entities, the user has to be authenticated and
authorized to do so. By default, newly registered users are not allowed to edit
entities. The interface is exactly the same as the one for adding new entities.

### Deleting entities

To be able to delete existing entities, the user has to be authenticated and
authorized to do so. By default, newly registered users are not allowed to
delete entities. The following routes handle `DELETE` requests for deleting
entities:

- `/persons/{id}`
- `/instruments/{id}`
- `/works/{id}`
- `/ensembles/{id}`
- `/recordings/{id}`

If the entity doesn't exist, an error `404` will be returned.