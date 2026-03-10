#include "onset_detector.h"

#include <cmath>
#include <algorithm>
#include <numeric>

OnsetDetector::OnsetDetector(int sample_rate, int frame_size)
    : sample_rate_(sample_rate),
      frame_size_(frame_size),
      fft_(frame_size, sample_rate),
      frames_since_last_onset_(kMinOnsetFrames), // allow onset on first frame
      current_frame_(0),
      last_onset_frame_(-1),
      bpm_(0.0f)
{}

void OnsetDetector::reset() {
    hfc_window_.clear();
    onset_frames_.clear();
    frames_since_last_onset_ = kMinOnsetFrames;
    current_frame_   = 0;
    last_onset_frame_ = -1;
    bpm_ = 0.0f;
}

bool OnsetDetector::detect(const int16_t* samples, int num_samples) {
    fft_.process(samples, num_samples);
    const float hfc = fft_.hfc();

    // ── Adaptive threshold from rolling mean ────────────────────────────────
    hfc_window_.push_back(hfc);
    if (static_cast<int>(hfc_window_.size()) > kWindowSize)
        hfc_window_.pop_front();

    float mean_hfc = 0.0f;
    for (float v : hfc_window_) mean_hfc += v;
    mean_hfc /= static_cast<float>(hfc_window_.size());

    const float threshold = mean_hfc * kOnsetMultiplier;

    // ── Onset detection ─────────────────────────────────────────────────────
    bool is_onset = false;
    if (hfc > threshold && frames_since_last_onset_ >= kMinOnsetFrames) {
        is_onset = true;
        frames_since_last_onset_ = 0;

        onset_frames_.push_back(current_frame_);
        if (static_cast<int>(onset_frames_.size()) > kMaxOnsets)
            onset_frames_.pop_front();

        last_onset_frame_ = current_frame_;
        update_bpm();
    } else {
        ++frames_since_last_onset_;
    }

    ++current_frame_;
    return is_onset;
}

// ── BPM estimation from inter-onset intervals ────────────────────────────────
// Converts frame-based IOIs to BPM and returns the most common value.
// Only updates when ≥ 4 onsets have been accumulated.
void OnsetDetector::update_bpm() {
    const int n_onsets = static_cast<int>(onset_frames_.size());
    if (n_onsets < 4) return;

    // Compute IOIs in seconds
    const float frame_duration = static_cast<float>(frame_size_) / sample_rate_;
    std::vector<float> bpms;
    bpms.reserve(n_onsets - 1);

    for (int i = 1; i < n_onsets; ++i) {
        const long long ioi_frames = onset_frames_[i] - onset_frames_[i - 1];
        if (ioi_frames <= 0) continue;
        const float ioi_s = ioi_frames * frame_duration;
        const float candidate_bpm = 60.0f / ioi_s;
        if (candidate_bpm >= 40.0f && candidate_bpm <= 240.0f)
            bpms.push_back(candidate_bpm);
    }

    if (bpms.empty()) return;

    // Histogram with 1-BPM bins in [40, 240]
    static constexpr int kBpmMin = 40;
    static constexpr int kBpmMax = 240;
    static constexpr int kBins   = kBpmMax - kBpmMin + 1;
    int hist[kBins] = {};

    for (float b : bpms) {
        int bin = static_cast<int>(std::round(b)) - kBpmMin;
        if (bin >= 0 && bin < kBins) hist[bin]++;
    }

    // Find the peak bin (allow +/-2 BPM smoothing window)
    int best_bin = 0;
    int best_count = 0;
    for (int i = 0; i < kBins; ++i) {
        int smoothed = hist[i];
        if (i > 0)       smoothed += hist[i - 1];
        if (i + 1 < kBins) smoothed += hist[i + 1];
        if (smoothed > best_count) {
            best_count = smoothed;
            best_bin   = i;
        }
    }

    bpm_ = static_cast<float>(best_bin + kBpmMin);
}
