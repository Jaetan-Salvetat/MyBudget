package fr.jaetan.mybudget.widget

import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import fr.jaetan.mybudget.R
import org.json.JSONArray
import java.text.NumberFormat
import java.util.Locale

class UpcomingPaymentsRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return UpcomingPaymentsRemoteViewsFactory(applicationContext)
    }
}

class UpcomingPaymentsRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class UpcomingItem(
        val name: String,
        val amount: Double,
        val day: Int,
        val type: String
    )

    private var items = listOf<UpcomingItem>()
    private val fmt = NumberFormat.getCurrencyInstance(Locale.FRANCE)

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("widget_upcoming_json", "[]") ?: "[]"
        val arr = try { JSONArray(json) } catch (_: Exception) { JSONArray() }

        val list = mutableListOf<UpcomingItem>()
        for (i in 0 until arr.length().coerceAtMost(8)) {
            val obj = arr.getJSONObject(i)
            list.add(UpcomingItem(
                name = obj.optString("name", ""),
                amount = obj.optString("amount", "0").toDoubleOrNull() ?: 0.0,
                day = obj.optInt("day", 0),
                type = obj.optString("type", "expense")
            ))
        }
        items = list
    }

    override fun onDestroy() {}

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_upcoming_row)
        try {
            val item = items[position]

            val palette = WidgetThemeHelper.getPalette(context)

            views.setTextViewText(R.id.tv_day, item.day.toString())
            views.setTextColor(R.id.tv_day, palette.onSurface)

            views.setTextViewText(R.id.tv_name, item.name)
            views.setTextColor(R.id.tv_name, palette.onSurface)

            val (iconRes, typeLabel, amountColor) = when (item.type) {
                "revenue" -> Triple(R.drawable.ic_widget_revenue, "Revenu", palette.positiveColor)
                "loan" -> Triple(R.drawable.ic_widget_loan, "Prêt", palette.primary)
                else -> Triple(R.drawable.ic_widget_expense, "Dépense", palette.negativeColor)
            }

            views.setImageViewResource(R.id.iv_type_icon, iconRes)
            views.setTextViewText(R.id.tv_type, typeLabel)
            views.setTextColor(R.id.tv_type, palette.onSurfaceVariant)

            val prefix = if (item.type == "revenue") "+" else "−"
            views.setTextViewText(R.id.tv_amount, "$prefix${fmt.format(item.amount)}")
            views.setTextColor(R.id.tv_amount, amountColor)
        } catch (e: Exception) {
            Log.e("UpcomingWidget", "Error in getViewAt($position)", e)
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
