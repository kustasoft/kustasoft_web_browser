import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum SafariViewControllerDismissButtonStyle { done, close, cancel }

class SafariViewControllerOptions {
  final bool barCollapsingEnabled;
  final bool entersReaderIfAvailable;
  final Color? preferredBarTintColor;
  final Color? preferredControlTintColor;
  final bool modalPresentationCapturesStatusBarAppearance;
  final SafariViewControllerDismissButtonStyle? dismissButtonStyle;
  final UIModalPresentationStyle modalPresentationStyle;

  const SafariViewControllerOptions({
    this.barCollapsingEnabled = false,
    this.entersReaderIfAvailable = false,
    this.preferredBarTintColor,
    this.preferredControlTintColor,
    this.modalPresentationCapturesStatusBarAppearance = false,
    this.dismissButtonStyle,
    this.modalPresentationStyle = UIModalPresentationStyle.overFullScreen,
  });
}

enum CustomTabsColorScheme {
  system, // 0x00000000
  light, // 0x00000001
  dark, // 0x00000002
}

enum CustomTabsShareState {
  default_, // 0x00000000
  on, // 0x00000001
  off, // 0x00000002
}

extension CustomTabsShareStateExtension on CustomTabsShareState {
  static CustomTabsShareState? fromAddDefaultShareMenuItem({
    bool? addDefaultShareMenuItem,
  }) {
    if (addDefaultShareMenuItem != null) {
      if (addDefaultShareMenuItem) {
        return CustomTabsShareState.on;
      } else {
        return CustomTabsShareState.off;
      }
    }

    return null;
  }
}

class CustomTabsColorSchemeParams {
  final Color? toolbarColor;
  final Color? secondaryToolbarColor;
  final Color? navigationBarColor;
  final Color? navigationBarDividerColor;

  const CustomTabsColorSchemeParams({
    this.toolbarColor,
    this.secondaryToolbarColor,
    this.navigationBarColor,
    this.navigationBarDividerColor,
  });

  Map<String, dynamic> toMethodChannelArgumentMap({
    Color? deprecatedToolbarColor,
    Color? deprecatedSecondaryToolbarColor,
    Color? deprecatedNavigationBarColor,
  }) {
    return {
      'toolbarColor': (toolbarColor ?? deprecatedToolbarColor)?.hexColor,
      'secondaryToolbarColor':
          (secondaryToolbarColor ?? deprecatedSecondaryToolbarColor)?.hexColor,
      'navigationBarColor':
          (navigationBarColor ?? deprecatedNavigationBarColor)?.hexColor,
      'navigationBarDividerColor': navigationBarDividerColor?.hexColor,
    };
  }
}

class CustomTabsOptions {
  final CustomTabsColorScheme colorScheme;
  final Color? toolbarColor;
  final Color? secondaryToolbarColor;
  final Color? navigationBarColor;
  final CustomTabsColorSchemeParams? lightColorSchemeParams;
  final CustomTabsColorSchemeParams? darkColorSchemeParams;
  final CustomTabsColorSchemeParams? defaultColorSchemeParams;
  final bool instantAppsEnabled;
  final bool? addDefaultShareMenuItem;
  final CustomTabsShareState? shareState;
  final bool showTitle;
  final bool urlBarHidingEnabled;

  const CustomTabsOptions({
    this.colorScheme = CustomTabsColorScheme.system,
    @Deprecated('Use defaultColorSchemeParams.toolbarColor instead')
    this.toolbarColor,
    @Deprecated('Use defaultColorSchemeParams.secondaryToolbarColor instead')
    this.secondaryToolbarColor,
    @Deprecated('Use defaultColorSchemeParams.navigationBarColor instead')
    this.navigationBarColor,
    this.lightColorSchemeParams,
    this.darkColorSchemeParams,
    this.defaultColorSchemeParams,
    this.instantAppsEnabled = false,
    @Deprecated('Use shareState instead') this.addDefaultShareMenuItem,
    this.shareState,
    this.showTitle = false,
    this.urlBarHidingEnabled = false,
  });
}

extension HexColor on Color {
  /// Returns the color value as ARGB hex value.
  String get hexColor {
    return '#${toARGB32().toRadixString(16).padLeft(8, '0')}';
  }
}

/// When supported, the built-in browser can notify of various events.
abstract class BrowserEvent {
  // Convenience constructor.
  static BrowserEvent? fromMap(Map<String, dynamic> map) {
    if (map['event'] == 'redirect') {
      return RedirectEvent(Uri.parse(map['url']));
    }
    if (map['event'] == 'close') {
      return CloseEvent();
    }

    return null;
  }
}

/// Describes a redirect.
class RedirectEvent extends BrowserEvent {
  RedirectEvent(this.url);

  /// New URL which is now visible.
  final Uri url;
}

/// Describes a close event (e.g. when the user closes the tab
/// or the [KustasoftWebBrowser.close] method was invoked).
class CloseEvent extends BrowserEvent {}

class KustasoftWebBrowser {
  // ignore: constant_identifier_names
  static const _NS = 'kustasoft_web_browser';
  static const MethodChannel _channel = MethodChannel(_NS);
  static const EventChannel _eventChannel = EventChannel('$_NS/events');

  static Future<bool> warmup() async {
    return await _channel.invokeMethod<bool>('warmup') ?? true;
  }

  /// Closes the currently open browser.
  ///
  /// This function will emit a [CloseEvent], which can be observed using [events].
  ///
  /// Only supported on iOS. Will not do anything on other platforms.
  static Future<void> close() async {
    if (!Platform.isIOS) {
      return;
    }

    await _channel.invokeMethod<void>('close');
  }

  /// Returns a stream of browser events which were observed while it was open.
  ///
  /// See [CloseEvent] & [RedirectEvent] for details on the events.
  ///
  /// Only supported on iOS. Returns a empty stream other platforms.
  static Stream<BrowserEvent> events() {
    if (!Platform.isIOS) {
      return Stream.empty();
    }

    return _eventChannel
        .receiveBroadcastStream()
        .map<Map<String, String>>((event) => Map<String, String>.from(event))
        .map((event) => BrowserEvent.fromMap(event)!);
  }

  static Future<void> openWebPage({
    required String url,
    CustomTabsOptions? customTabsOptions,
    SafariViewControllerOptions? safariVCOptions,
  }) {
    customTabsOptions ??= const CustomTabsOptions();
    safariVCOptions ??= const SafariViewControllerOptions();

    final CustomTabsColorSchemeParams customTabsDefaultColorSchemeParams =
        customTabsOptions.defaultColorSchemeParams ??
        CustomTabsColorSchemeParams(
          toolbarColor: customTabsOptions.toolbarColor,
          secondaryToolbarColor: customTabsOptions.secondaryToolbarColor,
          navigationBarColor: customTabsOptions.navigationBarColor,
        );
    final CustomTabsShareState customTabsShareState =
        customTabsOptions.shareState ??
        CustomTabsShareStateExtension.fromAddDefaultShareMenuItem(
          addDefaultShareMenuItem: customTabsOptions.addDefaultShareMenuItem,
        ) ??
        CustomTabsShareState.default_;

    return _channel.invokeMethod('openWebPage', {
      "url": url,
      'android_options': {
        'colorScheme': customTabsOptions.colorScheme.index,
        'lightColorSchemeParams':
            customTabsOptions.lightColorSchemeParams
                ?.toMethodChannelArgumentMap(),
        'darkColorSchemeParams':
            customTabsOptions.darkColorSchemeParams
                ?.toMethodChannelArgumentMap(),
        'defaultColorSchemeParams':
            customTabsDefaultColorSchemeParams.toMethodChannelArgumentMap(),
        'instantAppsEnabled': customTabsOptions.instantAppsEnabled,
        'shareState': customTabsShareState.index,
        'showTitle': customTabsOptions.showTitle,
        'urlBarHidingEnabled': customTabsOptions.urlBarHidingEnabled,
      },
      'ios_options': {
        'barCollapsingEnabled': safariVCOptions.barCollapsingEnabled,
        'entersReaderIfAvailable': safariVCOptions.entersReaderIfAvailable,
        'preferredBarTintColor':
            safariVCOptions.preferredBarTintColor?.hexColor,
        'preferredControlTintColor':
            safariVCOptions.preferredControlTintColor?.hexColor,
        'modalPresentationCapturesStatusBarAppearance':
            safariVCOptions.modalPresentationCapturesStatusBarAppearance,
        'dismissButtonStyle': safariVCOptions.dismissButtonStyle?.index,
        'modalPresentationStyle': safariVCOptions.modalPresentationStyle.name,
      },
    });
  }
}

/// Modal presentation styles available when presenting view controllers.
///
/// For more info see
/// https://developer.apple.com/documentation/uikit/uimodalpresentationstyle
enum UIModalPresentationStyle {
  /// The default presentation style chosen by the system.
  automatic,

  /// A presentation style that indicates no adaptations should be made.
  /// Not working
  none,

  /// A presentation style in which the presented view covers the screen.
  fullScreen,

  /// A presentation style that partially covers the underlying content.
  pageSheet,

  /// A presentation style that displays the content centered in the screen.
  formSheet,

  /// A presentation style where the content is displayed over another view controller’s content.
  currentContext,

  /// A view presentation style in which the presented view covers the screen.
  overFullScreen,

  /// A presentation style where the content is displayed over another view controller’s content.
  overCurrentContext,

  /// A presentation style where the content is displayed in a popover view.
  popover,

  /// A presentation style that blurs the underlying content before displaying new content in a full-screen presentation.
  blurOverFullScreen,
}
