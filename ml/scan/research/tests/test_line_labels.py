"""Projection des rôles annotés vers ce que les modèles prédisent."""

from __future__ import annotations

from annotate.schema import (
    CHANGE,
    FOOTER,
    HEADER,
    ITEM,
    ITEM_LABEL,
    NOISE,
    ROLES,
    STORE,
    SUMMARY,
    TAX,
)
from reference.line_labels import TAGGER_ROLES, UNREAD_ROLES, tagger_role


class TestTaggerRole:
    def test_un_role_lu_par_un_consommateur_est_garde(self) -> None:
        assert tagger_role(ITEM) == ITEM
        assert tagger_role(STORE) == STORE
        assert tagger_role(ITEM_LABEL) == ITEM_LABEL

    def test_les_roles_que_personne_ne_lit_se_confondent(self) -> None:
        """Six nuances de « on s'en fout » : aucun consommateur ne les
        distingue, et l'annotateur ne peut pas y être cohérent."""
        assert {tagger_role(role) for role in (TAX, CHANGE, SUMMARY, HEADER, FOOTER)} == {
            NOISE
        }

    def test_toute_projection_tombe_dans_le_contrat(self) -> None:
        assert {tagger_role(role) for role in ROLES} == set(TAGGER_ROLES)

    def test_le_contrat_ne_garde_aucun_role_non_lu_sauf_le_fourre_tout(self) -> None:
        assert set(TAGGER_ROLES) & set(UNREAD_ROLES) == {NOISE}

    def test_l_ordre_du_contrat_est_stable(self) -> None:
        """Le modèle rend un indice ; le renommer silencieusement désignerait
        la mauvaise ligne."""
        assert TAGGER_ROLES.index(STORE) == 0
        assert len(TAGGER_ROLES) == 9
