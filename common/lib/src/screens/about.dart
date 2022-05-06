import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: FutureBuilder<String>(
        future:
            rootBundle.loadString('packages/musicus_common/assets/about.md'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data,
              styleSheet: MarkdownStyleSheet(
                h1: textTheme.headline6.copyWith(
                  height: 2.0,
                ),
                a: textTheme.bodyText1.copyWith(
                  color: theme.accentColor,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTapLink: (text, href, title) => launchUrl(Uri.parse(href)),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
