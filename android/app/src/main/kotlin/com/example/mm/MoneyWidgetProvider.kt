package com.example.mm

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import android.net.Uri
import android.app.PendingIntent
import android.content.Intent

class MoneyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.money_widget_layout).apply {
                val balance = widgetData.getString("balance", "₹0.00")
                val income = widgetData.getString("income", "₹0.00")
                val expense = widgetData.getString("expense", "₹0.00")
                val lastUpdate = widgetData.getString("lastUpdate", "--:--")

                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_income, income)
                setTextViewText(R.id.widget_expense, expense)
                setTextViewText(R.id.widget_last_update, lastUpdate)

                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    context.packageManager.getLaunchIntentForPackage(context.packageName),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_title, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
