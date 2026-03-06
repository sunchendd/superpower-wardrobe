package com.superwardrobe

import android.app.Application

class SuperWardrobeApp : Application() {
    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    companion object {
        lateinit var instance: SuperWardrobeApp
            private set
    }
}
