package com.example.catalogo_legum_pro

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyBenchmarkDisplayPreference(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        applyBenchmarkDisplayPreference(intent)
    }

    @Suppress("DEPRECATION")
    private fun applyBenchmarkDisplayPreference(launchIntent: Intent?) {
        // Benchmark fixtures must never affect the real catalog or global settings.
        if (packageName != "com.example.catalogo_legum_pro.integration" ||
            Build.VERSION.SDK_INT < Build.VERSION_CODES.M
        ) return

        val requestedHz = launchIntent?.getIntExtra("PERF_DISPLAY_HZ", 0) ?: 0
        if (requestedHz != 60 && requestedHz != 120) return

        val activeDisplay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            windowManager.defaultDisplay
        } ?: return
        val supported = activeDisplay.supportedModes.filter {
            abs(it.refreshRate - requestedHz.toFloat()) <= 0.1f
        }
        val current = activeDisplay.mode
        val preferred = supported.firstOrNull {
            it.physicalWidth == current.physicalWidth &&
                it.physicalHeight == current.physicalHeight
        } ?: supported.firstOrNull() ?: return

        // The OS may ignore this window preference. Verify effective Hz per run.
        // https://developer.android.com/reference/android/view/WindowManager.LayoutParams
        val attributes = window.attributes
        attributes.preferredDisplayModeId = preferred.modeId
        attributes.preferredRefreshRate = requestedHz.toFloat()
        window.attributes = attributes
    }
}
