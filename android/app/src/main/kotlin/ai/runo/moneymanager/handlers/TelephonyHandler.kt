package ai.runo.moneymanager.handlers

import ai.runo.moneymanager.pigeon.SmsMessage
import ai.runo.moneymanager.pigeon.TelephonyApi
import android.content.Context
import android.database.Cursor
import android.net.Uri
import androidx.core.net.toUri

class TelephonyHandler(private val context: Context) : TelephonyApi {

    override fun readSMS(): List<SmsMessage?> {
        val smsList = mutableListOf<SmsMessage?>()
        val uri: Uri = "content://sms/inbox".toUri()
        val projection = arrayOf("address", "body", "date", "type")

        val cursor: Cursor? = context.contentResolver.query(uri, projection, null, null, "date DESC")

        cursor?.use {
            val addressIdx = it.getColumnIndex("address")
            val bodyIdx = it.getColumnIndex("body")
            val dateIdx = it.getColumnIndex("date")
            val typeIdx = it.getColumnIndex("type")

            while (it.moveToNext()) {
                val msg = SmsMessage(
                    address = it.getString(addressIdx),
                    body = it.getString(bodyIdx),
                    date = it.getString(dateIdx),
                    type = it.getString(typeIdx)
                )
                smsList.add(msg)
            }
        }

        return smsList
    }
}