package fr.jaetan.mybudget.nano

import com.google.mlkit.genai.schema.annotations.Generable
import com.google.mlkit.genai.schema.annotations.Guide

@Generable("Un article acheté, tel qu'il est imprimé sur le ticket")
data class ReceiptItemOutput(
    @Guide(description = "Le libellé de l'article, sans son prix ni sa quantité")
    val name: String,
    @Guide(
        description = "Le prix payé pour cette ligne, remise non déduite",
        minimum = 0.0,
    )
    val amount: Double,
    @Guide(
        description = "La remise portée sur cette ligne, 0 s'il n'y en a pas",
        minimum = 0.0,
    )
    val discount: Double,
)

@Generable("L'enseigne lue sur un ticket de caisse")
data class ReceiptStoreOutput(
    @Guide(
        description =
            "L'enseigne imprimée en tête du ticket, chaîne vide si elle " +
                "n'y figure pas",
    )
    val store: String,
)

@Generable("La date lue sur un ticket de caisse")
data class ReceiptDateOutput(
    @Guide(
        description =
            "La date d'achat, YYYY-MM-DD format, chaîne vide si elle n'y " +
                "figure pas",
    )
    val date: String,
)

@Generable("Les articles et le total lus sur un ticket de caisse")
data class ReceiptItemsOutput(
    @Guide(
        description = "Le total payé, 0 s'il n'est pas imprimé",
        minimum = 0.0,
    )
    val total: Double,
    @Guide(
        description = "Un élément par article acheté, dans l'ordre du ticket",
        maxItems = 80,
    )
    val items: List<ReceiptItemOutput>,
)

@Generable("Le total payé sur un ticket de caisse")
data class ReceiptTotalOutput(
    @Guide(
        description = "Le total payé imprimé en bas du ticket, 0 s'il n'y figure pas",
        minimum = 0.0,
    )
    val total: Double,
)
