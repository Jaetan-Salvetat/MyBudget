package fr.jaetan.mybudget.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import fr.jaetan.mybudget.R

object WidgetThemeHelper {

    fun isDarkMode(context: Context): Boolean {
        val uiMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return uiMode == Configuration.UI_MODE_NIGHT_YES
    }

    fun getPalette(context: Context): WidgetPalette {
        val isDark = isDarkMode(context)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return if (isDark) {
                WidgetPalette(
                    primary = context.getColor(android.R.color.system_accent1_200),
                    onPrimary = Color.WHITE,
                    surface = context.getColor(android.R.color.system_neutral1_900),
                    onSurface = context.getColor(android.R.color.system_neutral1_100),
                    onSurfaceVariant = context.getColor(android.R.color.system_neutral2_400),
                    positiveColor = Color.parseColor("#4ADE80"),
                    negativeColor = Color.parseColor("#F87171")
                )
            } else {
                WidgetPalette(
                    primary = context.getColor(android.R.color.system_accent1_600),
                    onPrimary = Color.WHITE,
                    surface = context.getColor(android.R.color.system_neutral1_10),
                    onSurface = context.getColor(android.R.color.system_neutral1_900),
                    onSurfaceVariant = context.getColor(android.R.color.system_neutral2_600),
                    positiveColor = Color.parseColor("#16A34A"),
                    negativeColor = Color.parseColor("#DC2626")
                )
            }
        }

        return if (isDark) {
            WidgetPalette(
                primary = Color.parseColor("#B39DDB"),
                onPrimary = Color.WHITE,
                surface = Color.parseColor("#1C1B1F"),
                onSurface = Color.parseColor("#E6E1E5"),
                onSurfaceVariant = Color.parseColor("#CAC4D0"),
                positiveColor = Color.parseColor("#4ADE80"),
                negativeColor = Color.parseColor("#F87171")
            )
        } else {
            WidgetPalette(
                primary = Color.parseColor("#6750A4"),
                onPrimary = Color.WHITE,
                surface = Color.parseColor("#FFFBFE"),
                onSurface = Color.parseColor("#1C1B1F"),
                onSurfaceVariant = Color.parseColor("#49454F"),
                positiveColor = Color.parseColor("#16A34A"),
                negativeColor = Color.parseColor("#DC2626")
            )
        }
    }

    fun applyBackground(views: RemoteViews, viewId: Int, isDark: Boolean) {
        val bgRes = if (isDark) R.drawable.widget_frosted_bg_dark else R.drawable.widget_frosted_bg_light
        views.setInt(viewId, "setBackgroundResource", bgRes)
    }
}

data class WidgetPalette(
    val primary: Int,
    val onPrimary: Int,
    val surface: Int,
    val onSurface: Int,
    val onSurfaceVariant: Int,
    val positiveColor: Int,
    val negativeColor: Int
)
