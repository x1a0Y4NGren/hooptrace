package io.github.x1a0y4ngren.hooptrace

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AutomaticBackupWorkPolicyTest {
    @Test
    fun usesOneDurableOfflineWorkNameAndTwentyFourHourCadence() {
        assertEquals("hooptrace.automatic-backup", AutomaticBackupWorkPolicy.uniqueWorkName)
        assertEquals(24L, AutomaticBackupWorkPolicy.periodicIntervalHours)
        assertFalse(AutomaticBackupWorkPolicy.requiresNetwork)
    }

    @Test
    fun treatsMissingSafAuthorizationAsACompletedSafeSkip() {
        assertEquals(
            AutomaticBackupWorkerOutcome.SKIPPED_NO_AUTHORIZATION,
            AutomaticBackupWorkerOutcome.fromWire("missing_authorization"),
        )
        assertFalse(AutomaticBackupWorkerOutcome.SKIPPED_NO_AUTHORIZATION.shouldRetry)
        assertTrue(AutomaticBackupWorkerOutcome.RETRY.shouldRetry)
        assertTrue(AutomaticBackupWorkerOutcome.fromWire("unexpected").shouldRetry)
    }
}
