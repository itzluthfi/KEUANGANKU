package com.danaku.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val expense = widgetData.getString("expense_value", "Rp 0")
                val income = widgetData.getString("income_value", "Rp 0")
                val balance = widgetData.getString("balance_value", "Rp 0")

                setTextViewText(R.id.widget_expense, "Pengeluaran: $expense")
                setTextViewText(R.id.widget_income, "Pemasukan: $income")
                setTextViewText(R.id.widget_balance, "Saldo: $balance")

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("danaku://add_transaction")
                )
                setOnClickPendingIntent(R.id.widget_btn_add, pendingIntent)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
