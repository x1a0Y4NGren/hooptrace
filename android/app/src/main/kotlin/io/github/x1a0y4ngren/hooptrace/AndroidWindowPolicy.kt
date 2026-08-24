package io.github.x1a0y4ngren.hooptrace

import android.graphics.Color
import android.os.Build
import android.view.Window
import androidx.annotation.RequiresApi

/**
 * Native window configuration owned by the Android shell.
 *
 * Flutter 3.41 uses edge-to-edge for API 35+ applications and owns the
 * system-bar appearance after the engine is attached. Applying the compatible
 * window flags here makes the policy explicit during the launch/engine handoff
 * and keeps older supported API levels safe through version guards.
 */
internal object AndroidWindowPolicy {
    const val predictiveBackMinApi = 33

    fun shouldEnablePredictiveBack(sdkInt: Int): Boolean {
        return sdkInt >= predictiveBackMinApi
    }

    fun shouldUsePlatformEdgeToEdge(sdkInt: Int): Boolean {
        return sdkInt >= Build.VERSION_CODES.R
    }

    // The guards use an injected SDK value so the policy stays unit-testable;
    // lint cannot infer that value is a platform version check.
    @Suppress("NewApi")
    fun apply(window: Window, sdkInt: Int = Build.VERSION.SDK_INT) {
        if (shouldUsePlatformEdgeToEdge(sdkInt)) {
            applyPlatformEdgeToEdge(window)
        }
        if (sdkInt >= Build.VERSION_CODES.Q) {
            applyTransparentSystemBars(window)
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    @Suppress("DEPRECATION")
    private fun applyPlatformEdgeToEdge(window: Window) {
        window.setDecorFitsSystemWindows(false)
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    @Suppress("DEPRECATION")
    private fun applyTransparentSystemBars(window: Window) {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        window.isNavigationBarContrastEnforced = false
    }
}
