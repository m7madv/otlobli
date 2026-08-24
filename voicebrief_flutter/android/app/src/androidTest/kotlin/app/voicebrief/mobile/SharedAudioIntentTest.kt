package app.voicebrief.mobile

import android.content.Intent
import android.net.Uri
import androidx.test.InstrumentationRegistry
import androidx.test.runner.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class SharedAudioIntentTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val testContext = instrumentation.context
    private val targetContext = instrumentation.targetContext

    @Test
    fun importsWhatsAppStyleOpusContentUriOnColdAndWarmShare() {
        targetContext.cacheDir.listFiles()
            ?.filter { it.name.startsWith("voicebrief_share_") }
            ?.forEach(File::delete)

        testContext.startActivity(
            shareIntent("PTT-20260824-WA-cold.opus").addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK,
            ),
        )
        waitForImportedFileCount(1)
        testContext.startActivity(
            shareIntent("PTT-20260824-WA-warm.opus").addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP,
            ),
        )
        waitForImportedFileCount(2)
    }

    private fun shareIntent(name: String) = Intent().apply {
        setClassName(targetContext.packageName, MainActivity::class.java.name)
        action = Intent.ACTION_SEND
        type = "audio/ogg"
        putExtra(
            Intent.EXTRA_STREAM,
            Uri.parse("content://app.voicebrief.mobile.test.shareprovider/$name"),
        )
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    private fun waitForImportedFileCount(expected: Int) {
        repeat(50) {
            val imported = targetContext.cacheDir.listFiles().orEmpty().filter {
                it.name.startsWith("voicebrief_share_") &&
                    it.extension == "ogg" &&
                    it.length() > 0
            }
            if (imported.size >= expected) return
            Thread.sleep(100)
        }
        val names = targetContext.cacheDir.listFiles().orEmpty().joinToString { it.name }
        assertTrue("Expected $expected imported OGG files; found: $names", false)
    }
}
