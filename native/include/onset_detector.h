#pragma once

#include "fft_util.h"
#include <cstdint>
#include <deque>
#include <vector>

/**
 * High-Frequency Content (HFC) onset detector with BPM estimation.
 *
 * Onset detection:
 *   An onset is declared when HFC(n) exceeds an adaptive threshold
 *   (rolling mean of previous frames × multiplier) with a minimum
 *   inter-onset interval of ~50 ms.
 *
 * BPM estimation:
 *   Inter-onset intervals (IOIs) are collected and histogrammed.
 *   The peak bin gives the estimated beat period → BPM.
 */
class OnsetDetector {
public:
    OnsetDetector(int sample_rate, int frame_size);

    /**
     * Process one frame. Returns true if a note onset is detected.
     * Updates the internal BPM estimate from accumulated onset times.
     */
    bool detect(const int16_t* samples, int num_samples);

    /** Current BPM estimate, or 0.0 if fewer than 4 onsets have been recorded. */
    float estimated_bpm() const { return bpm_; }

    /** Reset all state (call when starting a new recording session). */
    void reset();

private:
    int      sample_rate_;
    int      frame_size_;
    FftUtil  fft_;

    // Onset detection
    static constexpr int   kWindowSize      = 8;    // frames in rolling mean window
    static constexpr float kOnsetMultiplier = 1.5f; // HFC must exceed mean × this
    static constexpr int   kMinOnsetFrames  = 1;    // ≥1 frame between onsets (~46 ms)

    std::deque<float> hfc_window_;   // recent HFC values for adaptive threshold
    int               frames_since_last_onset_;
    long long         current_frame_;
    long long         last_onset_frame_;

    // BPM estimation
    static constexpr int kMaxOnsets = 32;
    std::deque<long long> onset_frames_; // ring buffer of last kMaxOnsets onset frame indices
    float bpm_;

    void update_bpm();
};
