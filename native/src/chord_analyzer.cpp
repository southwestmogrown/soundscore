#include "chord_analyzer.h"
// Phase 2: Chromagram + chord template matching goes here.

ChordAnalyzer::ChordAnalyzer(int sample_rate, int frame_size)
    : sample_rate_(sample_rate), frame_size_(frame_size) {}

std::string ChordAnalyzer::process(const int16_t* /*samples*/, int /*num_samples*/) {
    return ""; // Stub
}

void ChordAnalyzer::reset() {}
