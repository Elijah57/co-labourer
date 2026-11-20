/// A person is "active" when a conversation was logged within this window.
const activeWindow = Duration(days: 30);

bool isActive(DateTime? lastConversation, {DateTime? now}) {
  if (lastConversation == null) return false;
  final cutoff = (now ?? DateTime.now()).subtract(activeWindow);
  return lastConversation.isAfter(cutoff);
}
