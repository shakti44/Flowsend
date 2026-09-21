package com.flowsend.flowsend

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * FlowSend "Apps" screen — installed-app inventory.
 *
 * Uses PackageManager#queryIntentActivities() against ACTION_MAIN /
 * CATEGORY_LAUNCHER, which Android exempts from package-visibility
 * restrictions (the same mechanism every home-screen launcher uses). This
 * intentionally avoids QUERY_ALL_PACKAGES: FlowSend only ever sees apps a
 * launcher would already see, nothing more.
 */
class InstalledAppsManager(private val context: android.content.Context, private val messenger: BinaryMessenger) {

    fun attach() {
        MethodChannel(messenger, "flowsend/apps").setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> result.success(getInstalledApps())
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(launcherIntent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(launcherIntent, 0)
        }

        val seen = HashSet<String>()
        val apps = mutableListOf<Map<String, Any?>>()
        for (resolveInfo in resolveInfos) {
            val packageName = resolveInfo.activityInfo?.packageName ?: continue
            if (packageName == context.packageName || !seen.add(packageName)) continue

            val appInfo: ApplicationInfo = try {
                pm.getApplicationInfo(packageName, 0)
            } catch (error: PackageManager.NameNotFoundException) {
                continue
            }

            val label = pm.getApplicationLabel(appInfo).toString()
            val sourceDir = appInfo.sourceDir
            val sizeBytes = try {
                File(sourceDir).length()
            } catch (error: Exception) {
                0L
            }
            // Modern Android restricts reading other apps' installed APK bytes
            // (no private app data is copied) — only flag it as shareable when
            // this process can actually read the file.
            val isReadable = try {
                File(sourceDir).canRead()
            } catch (error: Exception) {
                false
            }

            apps.add(
                mapOf(
                    "name" to label,
                    "packageName" to packageName,
                    "sizeBytes" to sizeBytes,
                    "sourceDir" to sourceDir,
                    "isReadable" to isReadable,
                    "iconBytes" to iconBytes(pm, appInfo),
                ),
            )
        }
        return apps
    }

    private fun iconBytes(pm: PackageManager, appInfo: ApplicationInfo): ByteArray? {
        return try {
            val drawable = pm.getApplicationIcon(appInfo)
            val bitmap = drawableToBitmap(drawable)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (error: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) return drawable.bitmap
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
