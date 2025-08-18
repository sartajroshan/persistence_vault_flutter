package me.sartajroshan.persistence_vault

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.provider.Settings

import android.app.backup.BackupManager
import android.content.Context
import androidx.annotation.NonNull

/** PersistenceVaultPlugin */
class PersistenceVaultPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private lateinit var appContext: Context

  companion object {
    private const val CHANNEL = "persistence_vault/methods"
    private const val PREFS = "persistence_vault_prefs"
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, CHANNEL)
    channel.setMethodCallHandler(this)

  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    val editor = prefs.edit()
    val backupManager = BackupManager(appContext)

    when (call.method) {
      "getUDID" -> {
        val udid = getUDID()
        if (udid.isNullOrEmpty()) {
          result.error("UNAVAILABLE", "UDID not available.", null)
        } else {
          result.success(udid)
        }
      }

      "writeString" -> {
        val key = call.argument<String>("key")!!
        val value = call.argument<String>("value")
        editor.putString(key, value).apply()
        backupManager.dataChanged() // notify key/value backup
        result.success(null)
      }
      "readString" -> {
        val key = call.argument<String>("key")!!
        result.success(prefs.getString(key, null))
      }
      "delete" -> {
        val key = call.argument<String>("key")!!
        editor.remove(key).apply()
        backupManager.dataChanged()
        result.success(null)
      }
      "containsKey" -> {
        val key = call.argument<String>("key")!!
        result.success(prefs.contains(key))
      }
      "clearWithPrefix" -> {
        val prefix = call.argument<String>("prefix") ?: ""
        val toRemove = prefs.all.keys.filter { it.startsWith(prefix) }
        for (k in toRemove) editor.remove(k)
        editor.apply()
        backupManager.dataChanged()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun getUDID(): String? {
    return Settings.Secure.getString(
      appContext.contentResolver,
      Settings.Secure.ANDROID_ID
    )
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
