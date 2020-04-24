# Musicus

The classical music player and organizer.

https://musicus.org

## Project structure

The top level directories contain the main Musicus packages, of which some
depend on other ones. All packages are written in [Dart](https://dart.dev).

### `database`

A Database of classical music. This package will be used by all standalone
Musicus applications for storing classical music metadata.

### `mobile`

The Musicus mobile app. It is being developed using
[Flutter toolkit](https://flutter.dev) and only runs on Android for now.

### `player`

The simplest possible audio player plugin. This is used by the mobile app for
playback.

## Hacking

Picking up Dart as a programming language and Flutter as an UI toolkit should
be relatively straight forward. You can visit
[this page](https://flutter.dev/docs/get-started/install) to get started with
Flutter. After cloning the Musicus repository, it works best to work at its
subcomponents one at a time. I recommend
[VS Code](https://flutter.dev/docs/get-started/editor?tab=vscode) for editing.
Please contact me via e-mail (see my profile), if you have any questions or
need help. I'm also open to ideas for the future of Musicus! Please use the
issue tracker for them.

You can use the following command to automatically update generated code while
working on Musicus:

`flutter pub run build_runner watch`

## License

Musicus is free and open source software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

Musicus is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see https://www.gnu.org/licenses/.
