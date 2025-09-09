package com.sartajroshan.persistence_vault

import android.app.backup.BackupAgentHelper
import android.app.backup.SharedPreferencesBackupHelper

class PersistenceVaultBackupAgent : BackupAgentHelper() {

    companion object {
        // Must match the prefs file used in the plugin
        const val PREFS_NAME = "persistence_vault_prefs"
        private const val HELPER_KEY = "pv_prefs_helper"
    }

    override fun onCreate() {
        val helper = SharedPreferencesBackupHelper(this, PREFS_NAME)
        addHelper(HELPER_KEY, helper)
    }
}
