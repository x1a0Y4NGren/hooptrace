package io.github.x1a0y4ngren.hooptrace

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/** Enqueues exactly one persisted, reboot-safe automatic-backup worker. */
internal object AutomaticBackupWorkManager {
    fun schedule(context: Context) {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .build()
        val request = PeriodicWorkRequestBuilder<AutomaticBackupWorker>(
            AutomaticBackupWorkPolicy.periodicIntervalHours,
            TimeUnit.HOURS,
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                AutomaticBackupWorkPolicy.retryBackoffMinutes,
                TimeUnit.MINUTES,
            )
            .build()
        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            AutomaticBackupWorkPolicy.uniqueWorkName,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context.applicationContext)
            .cancelUniqueWork(AutomaticBackupWorkPolicy.uniqueWorkName)
    }
}
