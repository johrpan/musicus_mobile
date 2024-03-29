package de.johrpan.musicus_player

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

public class MusicusPlayerPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  private var playing = false
  private var uri: Uri? = null
  private var mediaPlayer: MediaPlayer? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "de.johrpan.musicus_player/platform")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.getApplicationContext()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "setUri") {
      val newUri = Uri.parse(call.argument<String>("uri"))
      uri = newUri

      if (mediaPlayer != null) {
        mediaPlayer?.release()
      }

      mediaPlayer = MediaPlayer.create(context, uri)
      mediaPlayer?.setOnCompletionListener {
        channel.invokeMethod("onComplete", null)
      }

      if (playing) {
        mediaPlayer?.start()
      }

      result.success(mediaPlayer?.getDuration())
    } else if (call.method == "play") {
      playing = true
      mediaPlayer?.start()
      result.success(null)
    } else if (call.method == "getPosition") {
      // TODO: Check, if mediaPlayer is in a valid state.
      result.success(mediaPlayer?.getCurrentPosition())
    } else if (call.method == "seekTo") {
      // TODO: Check, if mediaPlayer is in a valid state.
      mediaPlayer?.seekTo(call.argument("positionMs")!!)
      result.success(null)
    } else if (call.method == "pause") {
      playing = false
      mediaPlayer?.pause()
      result.success(null)
    } else if (call.method == "stop") {
      playing = false
      uri = null
      mediaPlayer?.release()
      mediaPlayer = null
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
