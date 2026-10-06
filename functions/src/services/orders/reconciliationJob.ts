import * as admin from "firebase-admin";

interface ReconciliationJobData {
  jobId: string;
  startedAt: Date;
  finishedAt?: Date;
  sweptAttemptIds: string[];
  resolved: number;
  stillPending: number;
  errors: Array<{ attemptId: string; errorCode: string; message: string }>;
}

export async function recordReconciliationJob(
  jobData: ReconciliationJobData
): Promise<void> {
  const db = admin.firestore();
  await db.collection("paymentReconciliationJobs").doc(jobData.jobId).set({
    jobId: jobData.jobId,
    startedAt: jobData.startedAt,
    finishedAt: jobData.finishedAt || null,
    sweptAttemptIds: jobData.sweptAttemptIds,
    resolved: jobData.resolved,
    stillPending: jobData.stillPending,
    errors: jobData.errors,
  });
}
