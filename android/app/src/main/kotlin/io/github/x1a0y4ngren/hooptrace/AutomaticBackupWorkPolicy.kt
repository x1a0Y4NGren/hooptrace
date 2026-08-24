package io.github.x1a0y4ngren.hooptrace

/** Stable native contract for the durable automatic-backup worker. */
internal object AutomaticBackupWorkPolicy {
    const val uniqueWorkName = "hooptrace.automatic-backup"
    const val storageChannelName =
        "io.github.x1a0y4ngren.hooptrace/automatic_backup"
    const val periodicIntervalHours = 24L
    const val retryBackoffMinutes = 30L
    const val requiresNetwork = false
    const val completionChannelName =
        "io.github.x1a0y4ngren.hooptrace/automatic_backup_background"

    const val successOutcome = "success"
    const val missingAuthorizationOutcome = "missing_authorization"
    const val retryOutcome = "retry"
}

internal enum class AutomaticBackupWorkerOutcome(
    val shouldRetry: Boolean,
) {
    SUCCESS(false),
    SKIPPED_NO_AUTHORIZATION(false),
    RETRY(true);

    companion object {
        fun fromWire(value: String?): AutomaticBackupWorkerOutcome {
            return when (value) {
                AutomaticBackupWorkPolicy.successOutcome -> SUCCESS
                AutomaticBackupWorkPolicy.missingAuthorizationOutcome ->
                    SKIPPED_NO_AUTHORIZATION
                AutomaticBackupWorkPolicy.retryOutcome -> RETRY
                else -> RETRY
            }
        }
    }
}
