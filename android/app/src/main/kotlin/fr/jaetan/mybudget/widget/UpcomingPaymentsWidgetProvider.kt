package fr.jaetan.mybudget.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import fr.jaetan.mybudget.MainActivity
import fr.jaetan.mybudget.R
import org.json.JSONArray

class UpcomingPaymentsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val isDark = WidgetThemeHelper.isDarkMode(context)
        val palette = WidgetThemeHelper.getPalette(context)

        val upcomingJson = widgetData.getString("widget_upcoming_json", "[]") ?: "[]"
        val items = try { JSONArray(upcomingJson) } catch (_: Exception) { JSONArray() }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_upcoming_payments)

            WidgetThemeHelper.applyBackground(views, R.id.widget_root, isDark)
            views.setTextColor(R.id.tv_title, palette.onSurfaceVariant)

            if (items.length() == 0) {
                views.setViewVisibility(R.id.tv_empty, View.VISIBLE)
                views.setViewVisibility(R.id.lv_upcoming, View.GONE)
                views.setViewVisibility(R.id.tv_count, View.GONE)
                views.setTextColor(R.id.tv_empty, palette.onSurfaceVariant)
            } else {
                views.setViewVisibility(R.id.tv_empty, View.GONE)
                views.setViewVisibility(R.id.lv_upcoming, View.VISIBLE)
                views.setViewVisibility(R.id.tv_count, View.VISIBLE)
                views.setTextViewText(R.id.tv_count, "${items.length()} ce mois")

                val serviceIntent = Intent(context, UpcomingPaymentsRemoteViewsService::class.java)
                views.setRemoteAdapter(R.id.lv_upcoming, serviceIntent)
            }

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 2, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.lv_upcoming)
        }
    }
}
