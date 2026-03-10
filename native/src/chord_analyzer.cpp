#include "chord_analyzer.h"

#include <cmath>
#include <algorithm>
#include <numeric>

// ── Krumhansl-Kessler key profiles (normalised) ──────────────────────────────
// Index 0 = C, 1 = C#, …, 11 = B
// Source: Krumhansl, C.L. (1990). "Cognitive Foundations of Musical Pitch."
const float ChordAnalyzer::kMajorProfile[12] = {
    6.35f, 2.23f, 3.48f, 2.33f, 4.38f, 4.09f,
    2.52f, 5.19f, 2.39f, 3.66f, 2.29f, 2.88f
};

const float ChordAnalyzer::kMinorProfile[12] = {
    6.33f, 2.68f, 3.52f, 5.38f, 2.60f, 3.53f,
    2.54f, 4.75f, 3.98f, 2.69f, 3.34f, 3.17f
};

const char* ChordAnalyzer::kNoteNames[12] = {
    "C", "C#", "D", "D#", "E", "F",
    "F#", "G", "G#", "A", "A#", "B"
};

ChordAnalyzer::ChordAnalyzer(int sample_rate, int frame_size)
    : sample_rate_(sample_rate),
      frame_size_(frame_size),
      fft_(frame_size, sample_rate),
      confidence_(0.0f)
{
    build_templates();
}

void ChordAnalyzer::reset() {
    confidence_ = 0.0f;
}

void ChordAnalyzer::build_templates() {
    // Build 12 major + 12 minor templates, each rotated to the appropriate root
    for (int root = 0; root < 12; ++root) {
        // Major template (index 0–11)
        ChordTemplate& maj = templates_[root];
        for (int pc = 0; pc < 12; ++pc)
            maj.weights[pc] = kMajorProfile[(pc - root + 12) % 12];
        maj.label = std::string(kNoteNames[root]);

        // Minor template (index 12–23)
        ChordTemplate& min = templates_[12 + root];
        for (int pc = 0; pc < 12; ++pc)
            min.weights[pc] = kMinorProfile[(pc - root + 12) % 12];
        min.label = std::string(kNoteNames[root]) + "m";
    }
}

// Pearson correlation between chromagram and chord template
float ChordAnalyzer::correlate(const float chroma[12], const ChordTemplate& tmpl) const {
    // Compute means
    float chroma_mean = 0.0f, tmpl_mean = 0.0f;
    for (int i = 0; i < 12; ++i) {
        chroma_mean += chroma[i];
        tmpl_mean   += tmpl.weights[i];
    }
    chroma_mean /= 12.0f;
    tmpl_mean   /= 12.0f;

    // Numerator and denominators
    float num = 0.0f, denom_c = 0.0f, denom_t = 0.0f;
    for (int i = 0; i < 12; ++i) {
        const float dc = chroma[i]       - chroma_mean;
        const float dt = tmpl.weights[i] - tmpl_mean;
        num    += dc * dt;
        denom_c += dc * dc;
        denom_t += dt * dt;
    }

    const float denom = std::sqrt(denom_c * denom_t);
    return (denom > 1e-10f) ? num / denom : 0.0f;
}

std::string ChordAnalyzer::process(const int16_t* samples, int num_samples) {
    fft_.process(samples, num_samples);

    float chroma[12];
    fft_.chromagram(chroma, kMinHz, kMaxHz);

    // Find the chord template with highest Pearson correlation
    float best_score = -1.0f;
    int   best_idx   = -1;
    for (int i = 0; i < 24; ++i) {
        const float score = correlate(chroma, templates_[i]);
        if (score > best_score) {
            best_score = score;
            best_idx   = i;
        }
    }

    // Map Pearson correlation [-1, 1] → confidence [0, 1]
    confidence_ = std::max(0.0f, (best_score + 1.0f) * 0.5f);

    if (best_score < kConfidenceThreshold || best_idx < 0)
        return "";

    return templates_[best_idx].label;
}
