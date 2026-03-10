#pragma once

#include <cstdint>
#include <vector>

extern "C" {
#include "kiss_fftr.h"
}

/**
 * FftUtil — Hann-windowed real FFT helper.
 *
 * Usage:
 *   FftUtil fft(2048, 44100);
 *   fft.process(pcm_int16, 2048);
 *   float mag = fft.magnitude(k);   // magnitude of bin k
 *   float hfc = fft.hfc();          // high-frequency content
 */
class FftUtil {
public:
    FftUtil(int frame_size, int sample_rate);
    ~FftUtil();

    /**
     * Process one frame of 16-bit PCM. Applies Hann window, runs FFT.
     * Must be called before accessing magnitude() / hfc().
     * @param samples  Pointer to frame_size int16_t samples.
     */
    void process(const int16_t* samples, int num_samples);

    /** Magnitude |X[k]| for FFT bin k, 0 ≤ k ≤ frame_size/2. */
    float magnitude(int k) const;

    /** Number of valid frequency bins (frame_size/2 + 1). */
    int num_bins() const { return frame_size_ / 2 + 1; }

    /** Frequency (Hz) of bin k. */
    float bin_frequency(int k) const {
        return static_cast<float>(k) * sample_rate_ / frame_size_;
    }

    /**
     * High Frequency Content: sum(k * |X[k]|^2) normalised by frame_size^2.
     * Useful for onset detection.
     */
    float hfc() const;

    /**
     * 12-bin chromagram: energy per pitch class (C=0 … B=11).
     * Accumulates magnitude across all harmonics in the given frequency range.
     * @param chroma  Output array of 12 floats (caller-allocated).
     * @param min_hz  Lower frequency bound (e.g. 41.2 Hz for bass E1).
     * @param max_hz  Upper frequency bound (e.g. 2000 Hz).
     */
    void chromagram(float chroma[12], float min_hz, float max_hz) const;

private:
    int             frame_size_;
    int             sample_rate_;
    kiss_fftr_cfg   cfg_;
    std::vector<float>          window_;       // Hann window
    std::vector<kiss_fft_scalar> time_buf_;    // windowed float samples
    std::vector<kiss_fft_cpx>   freq_buf_;    // complex spectrum (N/2+1 bins)
};
