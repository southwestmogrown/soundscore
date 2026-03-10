#pragma once
#include <cstdint>
#include <vector>

/**
 * YIN pitch detector (de Cheveigné & Kawahara, 2002).
 *
 * Detects the fundamental frequency of a monophonic signal using the
 * Cumulative Mean Normalized Difference Function with absolute threshold
 * and parabolic interpolation.
 *
 * Frequency range at 44100 Hz, frame_size 2048:
 *   min: ~43 Hz  (bass D#1 and above — covers all guitar/bass notes)
 *   max: ~22 kHz (Nyquist)
 */
class YinDetector {
public:
    /**
     * @param sample_rate  Audio sample rate in Hz (typically 44100).
     * @param frame_size   Processing frame size in samples (power of 2, e.g. 2048).
     *                     tau_max = frame_size / 2, giving min freq ≈ 43 Hz at 44100 Hz.
     */
    YinDetector(int sample_rate, int frame_size);

    /**
     * Process one frame. Returns the detected fundamental frequency in Hz,
     * or 0.0 if no pitch is detected.
     *
     * After calling, confidence() reflects detection certainty (0–1).
     */
    float process(const int16_t* samples, int num_samples);

    /** Detection confidence from the last call to process(): 0.0 = none, 1.0 = certain. */
    float confidence() const { return confidence_; }

    /** Reset internal state (call when starting a new session). */
    void reset();

private:
    int   sample_rate_;
    int   frame_size_;
    int   tau_max_;         // frame_size / 2
    float threshold_;       // aperiodicity threshold (0.15 per YIN paper)
    float confidence_;

    std::vector<float> diff_;       // difference function d(tau)
    std::vector<float> cmndf_;      // cumulative mean normalized difference d'(tau)
    std::vector<float> frame_f32_;  // int16 samples converted to float

    void   compute_difference();
    void   compute_cmndf();
    int    absolute_threshold() const; // returns best tau, or -1 if none below threshold
    float  parabolic_interpolation(int tau) const;
};
