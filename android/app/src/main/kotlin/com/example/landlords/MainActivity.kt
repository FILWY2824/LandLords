package com.example.landlords

import android.media.AudioManager
import android.media.MediaPlayer
import android.media.ToneGenerator
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private var textToSpeech: TextToSpeech? = null
    private var backgroundPlayer: MediaPlayer? = null
    private var toneGenerator: ToneGenerator? = null
    private var pendingText: String? = null
    private var pendingSpeakResult: MethodChannel.Result? = null
    private var activeUtteranceId: String? = null
    private var ttsReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        textToSpeech = TextToSpeech(this, this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "landlords/voice"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text").orEmpty()
                    speakText(text, result)
                }

                "stop" -> {
                    textToSpeech?.stop()
                    completeSpeakResult()
                    result.success(null)
                }

                "playErrorEffect" -> {
                    playErrorEffect()
                    result.success(null)
                }

                "startBackgroundMusic" -> {
                    startBackgroundMusic()
                    result.success(null)
                }

                "stopBackgroundMusic" -> {
                    stopBackgroundMusic()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        val tts = textToSpeech ?: return
        if (status == TextToSpeech.SUCCESS) {
            val localeResult = tts.setLanguage(Locale.SIMPLIFIED_CHINESE)
            ttsReady = localeResult != TextToSpeech.LANG_MISSING_DATA &&
                localeResult != TextToSpeech.LANG_NOT_SUPPORTED
            tts.setSpeechRate(0.95f)
            tts.setPitch(1.0f)
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) {
                    completeSpeakResult(utteranceId)
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    completeSpeakResult(utteranceId)
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    completeSpeakResult(utteranceId)
                }

                override fun onStop(utteranceId: String?, interrupted: Boolean) {
                    completeSpeakResult(utteranceId)
                }
            })
            pendingText?.let {
                val queuedResult = pendingSpeakResult
                pendingText = null
                pendingSpeakResult = null
                speakText(it, queuedResult)
            }
        } else {
            ttsReady = false
        }
    }

    private fun speakText(text: String, result: MethodChannel.Result? = null) {
        if (text.isBlank()) {
            result?.success(null)
            return
        }
        val tts = textToSpeech ?: run {
            result?.success(null)
            return
        }
        completeSpeakResult()
        if (!ttsReady) {
            pendingText = text
            pendingSpeakResult = result
            return
        }
        pendingSpeakResult = result
        val utteranceId = "landlords_voice_${System.currentTimeMillis()}"
        activeUtteranceId = utteranceId
        val status = tts.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            utteranceId
        )
        if (status != TextToSpeech.SUCCESS) {
            completeSpeakResult()
        }
    }

    private fun completeSpeakResult(utteranceId: String? = null) {
        runOnUiThread {
            if (utteranceId != null && activeUtteranceId != null && utteranceId != activeUtteranceId) {
                return@runOnUiThread
            }
            activeUtteranceId = null
            pendingSpeakResult?.success(null)
            pendingSpeakResult = null
        }
    }

    private fun startBackgroundMusic() {
        try {
            val player = backgroundPlayer ?: run {
                val descriptor = assets.openFd("flutter_assets/assets/audio/background_music.mp3")
                MediaPlayer().apply {
                    setDataSource(
                        descriptor.fileDescriptor,
                        descriptor.startOffset,
                        descriptor.length
                    )
                    isLooping = true
                    setVolume(0.22f, 0.22f)
                    prepare()
                }.also {
                    descriptor.close()
                    backgroundPlayer = it
                }
            }
            if (!player.isPlaying) {
                player.start()
            }
        } catch (_: Exception) {
        }
    }

    private fun playErrorEffect() {
        try {
            val generator = toneGenerator ?: ToneGenerator(AudioManager.STREAM_NOTIFICATION, 95).also {
                toneGenerator = it
            }
            generator.startTone(ToneGenerator.TONE_PROP_NACK, 180)
        } catch (_: Exception) {
        }
    }

    private fun stopBackgroundMusic() {
        try {
            backgroundPlayer?.pause()
            backgroundPlayer?.seekTo(0)
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        stopBackgroundMusic()
        backgroundPlayer?.release()
        backgroundPlayer = null
        toneGenerator?.release()
        toneGenerator = null
        completeSpeakResult()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }
}
