#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Result of processing one audio frame.
 * Returned by soundscore_process_frame().
 */
typedef struct {
    float frequency;   /**< Detected fundamental frequency in Hz. 0 if no pitch. */
    int   midi_note;   /**< MIDI note number 0-127. -1 if no pitch detected.     */
    float confidence;  /**< Pitch detection confidence 0.0 (none) - 1.0 (high).  */
    int   is_onset;    /**< 1 if a new note onset was detected in this frame.     */
} SoundScorePitchResult;

/** Opaque DSP context handle. */
typedef struct SoundScoreDspContext SoundScoreDspContext;

/**
 * Allocate a new DSP context.
 *
 * @param sample_rate  Audio sample rate in Hz (typically 44100).
 * @param frame_size   Number of samples per processing frame (power of 2, e.g. 2048).
 * @return             Heap-allocated context. Must be freed with soundscore_destroy().
 */
SoundScoreDspContext* soundscore_create(int sample_rate, int frame_size);

/**
 * Free a DSP context previously created with soundscore_create().
 */
void soundscore_destroy(SoundScoreDspContext* ctx);

/**
 * Process one frame of 16-bit signed PCM audio.
 *
 * Thread-safe: can be called from an audio thread; does no memory allocation.
 *
 * @param ctx          DSP context.
 * @param samples      Pointer to interleaved mono PCM samples.
 * @param num_samples  Number of samples in this frame (must equal frame_size).
 * @return             Pitch detection result for this frame.
 */
SoundScorePitchResult soundscore_process_frame(
    SoundScoreDspContext* ctx,
    const int16_t*        samples,
    int                   num_samples
);

/**
 * Get the current BPM estimate (updated continuously from onset times).
 *
 * @return  Estimated BPM, or 0.0 if not enough onsets collected yet.
 */
float soundscore_get_bpm(SoundScoreDspContext* ctx);

/**
 * Get the chord label detected in the most recent frame.
 *
 * @param ctx  DSP context.
 * @param buf  Output buffer to receive a null-terminated chord label string
 *             (e.g. "Am", "G", "F#m"). Empty string if no chord was detected.
 * @param buf_size  Size of the output buffer in bytes. 8 bytes is sufficient.
 * @return     Actual string length (excluding null terminator), or 0 if none.
 */
int soundscore_get_chord(SoundScoreDspContext* ctx, char* buf, int buf_size);

/**
 * Get the confidence of the most recently detected chord (0.0–1.0).
 */
float soundscore_get_chord_confidence(SoundScoreDspContext* ctx);

/**
 * Reset accumulated note/onset history (call when starting a new recording session).
 */
void soundscore_reset(SoundScoreDspContext* ctx);

#ifdef __cplusplus
} // extern "C"
#endif
