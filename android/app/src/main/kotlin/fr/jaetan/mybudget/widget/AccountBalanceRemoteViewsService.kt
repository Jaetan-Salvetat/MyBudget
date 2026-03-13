package fr.jaetan.mybudget.widget

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import fr.jaetan.mybudget.R
import org.json.JSONArray
import java.text.NumberFormat
import java.util.Locale

class AccountBalanceRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return AccountBalanceRemoteViewsFactory(applicationContext)
    }
}

class AccountBalanceRemoteViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private data class AccountItem(val name: String, val bank: String, val balance: Double)

    private var accounts = listOf<AccountItem>()
    private val fmt = NumberFormat.getCurrencyInstance(Locale.FRANCE)

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("widget_accounts_json", "[]") ?: "[]"
        val arr = try { JSONArray(json) } catch (_: Exception) { JSONArray() }

        val list = mutableListOf<AccountItem>()
        for (i in 0 until arr.length().coerceAtMost(6)) {
            val obj = arr.getJSONObject(i)
            list.add(AccountItem(
                name = obj.optString("name", ""),
                bank = obj.optString("bank", ""),
                balance = obj.optString("balance", "0").toDoubleOrNull() ?: 0.0
            ))
        }
        accounts = list
    }

    override fun onDestroy() {}

    override fun getCount(): Int = accounts.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_account_row)
        val account = accounts[position]

        views.setTextViewText(R.id.tv_account_name, account.name)
        views.setTextViewText(R.id.tv_account_bank, account.bank)
        views.setTextViewText(R.id.tv_account_balance, fmt.format(account.balance))
        views.setTextColor(
            R.id.tv_account_balance,
            if (account.balance >= 0) context.getColor(R.color.widget_positive)
            else context.getColor(R.color.widget_negative)
        )

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false
}
