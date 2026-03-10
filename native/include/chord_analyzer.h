#pragma once
#include <cstdint>
#include <string>

/// Chromagram-based chord detection (guitar + bass, v1).
/// Full implementation in Phase 2.
class ChordAnalyzer {
public:
    ChordAnalyzer(int sample_rate, int frame_size);

    /// Returns chord label (e.g. "Am", "G", "Dm7") or empty string if undetected.
    std::string process(const int16_t* samples, int num_samples);

    void reset();

private:
    int sample_rate_;
    int frame_size_;
};
