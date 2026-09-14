enum ReportReason { harassment, inappropriateContent, fakeProfile, spam, safetyConcern, other }

extension ReportReasonLabel on ReportReason {
  String get label => switch (this) {
    ReportReason.harassment => 'Harassment',
    ReportReason.inappropriateContent => 'Inappropriate content',
    ReportReason.fakeProfile => 'Fake or misleading profile',
    ReportReason.spam => 'Spam',
    ReportReason.safetyConcern => 'Safety concern',
    ReportReason.other => 'Other',
  };
}
