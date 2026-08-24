from flow import (
    CLOUD,
    CONFIRM,
    LOCAL,
    LOCAL_RETRY,
    FlowPolicy,
    decide,
)
from structure import ExtractedItem, ExtractedReceipt


def receipt(
    amounts: list[float],
    total: float | None,
    payment: float | None = None,
) -> ExtractedReceipt:
    return ExtractedReceipt(
        store=None,
        date=None,
        total=total,
        subtotal=None,
        payment=payment,
        items=[
            ExtractedItem(name=f"ART{i}", amount=amount, discount=0.0)
            for i, amount in enumerate(amounts)
        ],
    )


STRICT = FlowPolicy()


class TestLocalStages:
    def test_local_checksum_ok_validates_directly(self):
        outcome = decide(receipt([2.0, 3.0], 5.0), None, None, None, STRICT)
        assert outcome.stage == LOCAL
        assert outcome.items == [(2.0, 0.0), (3.0, 0.0)]

    def test_retry_rescues_failed_first_pass(self):
        outcome = decide(
            receipt([2.0], 5.0), receipt([2.0, 3.0], 5.0), None, None, STRICT
        )
        assert outcome.stage == LOCAL_RETRY
        assert outcome.items == [(2.0, 0.0), (3.0, 0.0)]

    def test_local_ok_wins_over_everything(self):
        outcome = decide(
            receipt([5.0], 5.0),
            receipt([1.0, 4.0], 5.0),
            [(9.0, 0.0)],
            9.0,
            STRICT,
        )
        assert outcome.stage == LOCAL


class TestCloudEscalation:
    def test_cloud_accepted_when_sum_matches_cloud_total(self):
        outcome = decide(
            receipt([2.0], 5.0), None, [(2.0, 0.0), (3.0, 0.0)], 5.0, STRICT
        )
        assert outcome.stage == CLOUD
        assert outcome.items == [(2.0, 0.0), (3.0, 0.0)]
        assert outcome.total == 5.0

    def test_cloud_discounts_count_in_checksum(self):
        outcome = decide(
            receipt([2.0], 5.0), None, [(3.0, 1.0), (3.0, 0.0)], 5.0, STRICT
        )
        assert outcome.stage == CLOUD

    def test_cloud_rejected_when_sum_diverges(self):
        outcome = decide(
            receipt([2.0], 5.0), None, [(2.0, 0.0)], 5.0, STRICT
        )
        assert outcome.stage == CONFIRM

    def test_cloud_rejected_without_total(self):
        outcome = decide(
            receipt([2.0], 5.0), None, [(2.0, 0.0)], None, STRICT
        )
        assert outcome.stage == CONFIRM

    def test_tolerance_absorbs_rounding_gap(self):
        policy = FlowPolicy(tolerance=0.02)
        outcome = decide(
            receipt([2.0], 5.0), None, [(2.0, 0.0), (3.01, 0.0)], 5.0, policy
        )
        assert outcome.stage == CLOUD

    def test_strict_rejects_rounding_gap(self):
        outcome = decide(
            receipt([2.0], 5.0), None, [(2.0, 0.0), (3.01, 0.0)], 5.0, STRICT
        )
        assert outcome.stage == CONFIRM


class TestCrossCheck:
    POLICY = FlowPolicy(cross_check_local_total=True)

    def test_cloud_rejected_when_totals_disagree(self):
        outcome = decide(
            receipt([2.0], 21.0), None, [(20.0, 0.0)], 20.0, self.POLICY
        )
        assert outcome.stage == CONFIRM

    def test_cloud_accepted_when_totals_agree(self):
        outcome = decide(
            receipt([2.0], 20.0), None, [(20.0, 0.0)], 20.0, self.POLICY
        )
        assert outcome.stage == CLOUD

    def test_cloud_accepted_when_no_local_total(self):
        outcome = decide(
            receipt([2.0], None), None, [(20.0, 0.0)], 20.0, self.POLICY
        )
        assert outcome.stage == CLOUD

    def test_retry_total_serves_as_reference(self):
        outcome = decide(
            receipt([2.0], None),
            receipt([2.0], 21.0),
            [(20.0, 0.0)],
            20.0,
            self.POLICY,
        )
        assert outcome.stage == CONFIRM


class TestConfirmPrefill:
    def test_prefill_cloud_by_default(self):
        outcome = decide(
            receipt([2.0], 5.0), None, [(9.0, 0.0)], 8.0, STRICT
        )
        assert outcome.stage == CONFIRM
        assert outcome.items == [(9.0, 0.0)]

    def test_prefill_local_when_policy_says_so(self):
        policy = FlowPolicy(confirm_prefill="local")
        outcome = decide(
            receipt([2.0], 5.0), None, [(9.0, 0.0)], 8.0, policy
        )
        assert outcome.items == [(2.0, 0.0)]

    def test_prefill_falls_back_to_retry_without_cloud(self):
        outcome = decide(
            receipt([2.0], 9.0), receipt([2.0, 3.0], 9.0 + 1), None, None, STRICT
        )
        assert outcome.stage == CONFIRM
        assert outcome.items == [(2.0, 0.0), (3.0, 0.0)]

    def test_prefill_falls_back_to_local_without_retry(self):
        outcome = decide(receipt([2.0], 9.0), None, None, None, STRICT)
        assert outcome.stage == CONFIRM
        assert outcome.items == [(2.0, 0.0)]


class TestRetryValueGuard:
    POLICY = FlowPolicy(retry_must_not_lose_value=True)

    def test_retry_losing_value_goes_to_confirm(self):
        outcome = decide(
            receipt([7.05, 5.5, 9.9], 9.9),
            receipt([7.05, 5.5], 12.55),
            None,
            None,
            self.POLICY,
        )
        assert outcome.stage == CONFIRM

    def test_retry_with_equal_value_still_validates(self):
        outcome = decide(
            receipt([2.0, 3.0], 6.0),
            receipt([2.0, 3.0], 5.0),
            None,
            None,
            self.POLICY,
        )
        assert outcome.stage == LOCAL_RETRY

    def test_retry_gaining_items_still_validates(self):
        outcome = decide(
            receipt([2.0], 5.0),
            receipt([2.0, 3.0], 5.0),
            None,
            None,
            self.POLICY,
        )
        assert outcome.stage == LOCAL_RETRY

    def test_guard_off_keeps_previous_behaviour(self):
        outcome = decide(
            receipt([7.05, 5.5, 9.9], 9.9),
            receipt([7.05, 5.5], 12.55),
            None,
            None,
            FlowPolicy(),
        )
        assert outcome.stage == LOCAL_RETRY
