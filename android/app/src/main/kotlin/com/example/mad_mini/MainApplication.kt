package com.example.mad_mini

import io.flutter.app.FlutterApplication
import androidx.multidex.MultiDex
import android.content.Context

class MainApplication : FlutterApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
} 