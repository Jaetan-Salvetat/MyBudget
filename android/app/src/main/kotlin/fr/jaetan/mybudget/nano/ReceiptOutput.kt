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

@Generable("Les informations lues sur un ticket de caisse")
data class ReceiptOutput(
    @Guide(
        description =
            "L'enseigne imprimée en tête du ticket, chaîne vide si elle " +
                "n'y figure pas",
    )
    val store: String,
    @Guide(
        description =
            "La date d'achat au format AAAA-MM-JJ, chaîne vide si elle n'y " +
                "figure pas",
    )
    val date: String,
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
