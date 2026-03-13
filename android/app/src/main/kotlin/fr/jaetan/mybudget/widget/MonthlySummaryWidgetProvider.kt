package fr.jaetan.mybudget.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import fr.jaetan.mybudget.MainActivity
import fr.jaetan.mybudget.R
import java.text.NumberFormat
import java.util.Locale

class MonthlySummaryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val fmt = NumberFormat.getCurrencyInstance(Locale.FRANCE)

        val revenues = widgetData.getString("widget_monthly_revenues", "0")?.toDoubleOrNull() ?: 0.0
        val expenses = widgetData.getString("widget_monthly_expenses", "0")?.toDoubleOrNull() ?: 0.0
        val loanPayments = widgetData.getString("widget_monthly_loan_payments", "0")?.toDoubleOrNull() ?: 0.0
        val netBalance = widgetData.getString("widget_net_balance", "0")?.toDoubleOrNull() ?: 0.0

        val positiveColor = context.getColor(R.color.widget_positive)
        val negativeColor = context.getColor(R.color.widget_negative)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_monthly_summary)

            views.setTextViewText(R.id.tv_net_balance, fmt.format(netBalance))
            views.setTextColor(R.id.tv_net_balance, if (netBalance >= 0) positiveColor else negativeColor)
            views.setTextViewText(R.id.tv_revenues_amount, fmt.format(revenues))
            views.setTextViewText(R.id.tv_expenses_amount, fmt.format(expenses + loanPayments))

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
