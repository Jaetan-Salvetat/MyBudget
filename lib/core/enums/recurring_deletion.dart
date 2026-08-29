/// How far back deleting a recurring rule reaches.
///
/// A rule already honoured this month leaves a real payment behind, and
/// erasing it would rewrite a month that is done. One whose turn has not come
/// round leaves nothing, so keeping the month would announce a payment that
/// will never happen. Which of the two applies is the reader's call, not the
/// calendar's — this only says what was chosen.
enum RecurringDeletion {
  /// The month in progress keeps its occurrence ; the rule stops after it.
  afterThisMonth,

  /// The month in progress loses its occurrence too.
  includingThisMonth,
}
