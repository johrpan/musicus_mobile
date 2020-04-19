package de.johrpan.musicus_player

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

public class MusicusPlayerPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "de.johrpan.musicus_player/platform")
    channel.setMethodCallHandler(this);
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    // TODO: Implement.
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
