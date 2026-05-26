package com.example.ruh_huzur

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_home_widget)
            val nextPrayer = widgetData.getString("next_prayer", "Sıradaki vakit")
            val nextPrayerTime = widgetData.getString("next_prayer_time", "")
            val timeUntil = widgetData.getString("time_until_next", "Vakitler güncelleniyor")
            val city = widgetData.getString("city", "İstanbul")

            views.setTextViewText(R.id.widget_next_prayer, "$nextPrayer $nextPrayerTime")
            views.setTextViewText(R.id.widget_countdown, timeUntil)
            views.setTextViewText(R.id.widget_city, city)

            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { intent ->
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
