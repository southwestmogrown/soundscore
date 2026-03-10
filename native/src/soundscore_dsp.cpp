#include "soundscore_dsp.h"
#include "yin_detector.h"
#include "onset_detector.h"
#include "chord_analyzer.h"

#include <cmath>
#include <cstdlib>
#include <new>

struct SoundScoreDspContext {
    int sample_rate;
    int frame_size;
    YinDetector    yin;
    OnsetDetector  onset;
    ChordAnalyzer  chord;

    SoundScoreDspContext(int sr, int fs)
        : sample_rate(sr), frame_size(fs),
          yin(sr, fs), onset(sr, fs), chord(sr, fs) {}
};

extern "C" {

SoundScoreDspContext* soundscore_create(int sample_rate, int frame_size) {
    return new (std::nothrow) SoundScoreDspContext(sample_rate, frame_size);
}

void soundscore_destroy(SoundScoreDspContext* ctx) {
    delete ctx;
}

SoundScorePitchResult soundscore_process_frame(
    SoundScoreDspContext* ctx,
    const int16_t*        samples,
    int                   num_samples
) {
    SoundScorePitchResult result{};
    if (!ctx || !samples || num_samples <= 0) return result;

    // Phase 2: real YIN + onset processing goes here
    result.frequency  = ctx->yin.process(samples, num_samples);
    result.is_onset   = ctx->onset.detect(samples, num_samples) ? 1 : 0;
    result.confidence = ctx->yin.confidence();

    if (result.frequency > 0.0f && result.confidence > 0.15f) {
        // frequency -> MIDI: midi = 69 + 12 * log2(freq / 440)
        result.midi_note = static_cast<int>(
            std::round(69.0f + 12.0f * std::log2(result.frequency / 440.0f))
        );
    } else {
        result.midi_note = -1;
        result.frequency  = 0.0f;
    }

    return result;
}

float soundscore_get_bpm(SoundScoreDspContext* ctx) {
    if (!ctx) return 0.0f;
    return ctx->onset.estimated_bpm();
}

void soundscore_reset(SoundScoreDspContext* ctx) {
    if (!ctx) return;
    ctx->yin.reset();
    ctx->onset.reset();
    ctx->chord.reset();
}

} // extern "C"
