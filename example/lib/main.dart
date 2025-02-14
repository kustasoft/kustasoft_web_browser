import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kustasoft_web_browser/kustasoft_web_browser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> openBrowserTab() async {
    await KustasoftWebBrowser.openWebPage(url: "https://flutter.io/");
  }

  final List<BrowserEvent> _events = [];

  StreamSubscription<BrowserEvent>? _browserEvents;

  @override
  void initState() {
    super.initState();

    _browserEvents = KustasoftWebBrowser.events().listen((event) {
      setState(() {
        _events.add(event);
      });
    });
  }

  @override
  void dispose() {
    _browserEvents?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Plugin example app')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton(
                  onPressed: () => KustasoftWebBrowser.warmup(),
                  child: Text('Warmup browser website'),
                ),
                TextButton(
                  onPressed: () => openBrowserTab(),
                  child: Text('Open Flutter website'),
                ),
                TextButton(
                  onPressed:
                      () => openBrowserTab().then(
                        (value) => Future.delayed(
                          Duration(seconds: 5),
                          () => KustasoftWebBrowser.close(),
                        ),
                      ),
                  child: Text('Open Flutter website & close after 5 seconds'),
                ),
                if (Platform.isAndroid) ...[
                  Text('test Android customizations'),
                  TextButton(
                    onPressed: () {
                      KustasoftWebBrowser.openWebPage(
                        url: "https://flutter.io/",
                        customTabsOptions: CustomTabsOptions(
                          colorScheme: CustomTabsColorScheme.dark,
                          darkColorSchemeParams: CustomTabsColorSchemeParams(
                            toolbarColor: Colors.deepPurple,
                            secondaryToolbarColor: Colors.green,
                            navigationBarColor: Colors.amber,
                            navigationBarDividerColor: Colors.cyan,
                          ),
                          shareState: CustomTabsShareState.on,
                          instantAppsEnabled: true,
                          showTitle: true,
                          urlBarHidingEnabled: true,
                        ),
                      );
                    },
                    child: Text('Open Flutter website'),
                  ),
                ],
                if (Platform.isIOS) ...[
                  Text('test iOS customizations'),
                  TextButton(
                    onPressed: () {
                      KustasoftWebBrowser.openWebPage(
                        url: "https://flutter.io/",
                        safariVCOptions: SafariViewControllerOptions(
                          barCollapsingEnabled: true,
                          preferredBarTintColor: Colors.green,
                          preferredControlTintColor: Colors.amber,
                          dismissButtonStyle:
                              SafariViewControllerDismissButtonStyle.close,
                          modalPresentationCapturesStatusBarAppearance: true,
                          modalPresentationStyle:
                              UIModalPresentationStyle.popover,
                        ),
                      );
                    },
                    child: Text('Open Flutter website'),
                  ),
                  Divider(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        _events.map((e) {
                          if (e is RedirectEvent) {
                            return Text('redirect: ${e.url}');
                          }
                          if (e is CloseEvent) {
                            return Text('closed');
                          }

                          return Text('Unknown event: $e');
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
