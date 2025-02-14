package com.kustasoft.kustasoft_web_browser;

import android.app.Activity;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
// Import the MethodCallHandlerImpl class
import com.kustasoft.kustasoft_web_browser.MethodCallHandlerImpl;

/** KustasoftWebBrowserPlugin */
public class KustasoftWebBrowserPlugin implements FlutterPlugin, ActivityAware {

  private MethodChannel methodChannel;
  private MethodCallHandlerImpl methodCallHandler;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    startListening(binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    stopListening();
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    setActivity(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    setActivity(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    setActivity(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    setActivity(null);
  }

  private void startListening(BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, "kustasoft_web_browser");
    methodCallHandler = new MethodCallHandlerImpl();
    methodChannel.setMethodCallHandler(methodCallHandler);
  }

  private void setActivity(@Nullable Activity activity) {
    methodCallHandler.setActivity(activity);
  }

  private void stopListening() {
    methodChannel.setMethodCallHandler(null);
    methodChannel = null;
  }
}