package com.angelasoft.angela_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /** 서버(PushSender.ANDROID_CHANNEL_ID)가 지정하는 채널. 중요도를 높여 화면 위에 알림이 뜨게 한다. */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.default_notification_channel_id),
            "쁘레시디움 알림",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "간부 선거, 신청 승인 등 쁘레시디움 소식"
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
