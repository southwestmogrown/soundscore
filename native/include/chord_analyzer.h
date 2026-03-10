#pragma once

#include "fft_util.h"
#include <cstdint>
#include <string>
#include <array>

/**
 * Chromagram-based chord detector.
 *
 * Computes a 12-bin pitch-class profile (chromagram) via FFT, then
 * correlates it against 24 major/minor chord templates (Krumhansl-Kessler
 * profiles) to identify the most likely chord.
 *
 * Supported instruments:
 *   Guitar: E2–B5  (~82 Hz – ~990 Hz + harmonics up to 4 kHz)
 *   Bass:   E1–G4  (~41 Hz – ~392 Hz + harmonics up to 2 kHz)
 */
class ChordAnalyzer {
public:
    ChordAnalyzer(int sample_rate, int frame_size);

    /**
     * Process one frame.
     * @return Chord label string ("Am", "G", "F#m", …) or "" if confidence
     *         is below the detection threshold.
     */
    std::string process(const int16_t* samples, int num_samples);

    /** Confidence of the last detected chord (0–1). */
    float confidence() const { return confidence_; }

    void reset();

private:
    int     sample_rate_;
    int     frame_size_;
    FftUtil fft_;
    float   confidence_;

    // Detection threshold: correlation must exceed this to report a chord
    static constexpr float kConfidenceThreshold = 0.55f;

    // Frequency bounds cover guitar + bass fundamentals and harmonics
    static constexpr float kMinHz = 41.0f;   // bass E1
    static constexpr float kMaxHz = 4000.0f; // 4th harmonic of guitar high E

    // Chord template helpers
    static const float kMajorProfile[12]; // Krumhansl-Kessler major key profile
    static const float kMinorProfile[12]; // Krumhansl-Kessler minor key profile
    static const char* kNoteNames[12];

    struct ChordTemplate {
        std::array<float, 12> weights;
        std::string           label;
    };

    std::array<ChordTemplate, 24> templates_; // 12 major + 12 minor

    void build_templates();
    float correlate(const float chroma[12], const ChordTemplate& tmpl) const;
};
