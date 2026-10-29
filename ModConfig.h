#pragma once
// Bản khung tự viết, không sao chép code của bên khác.
// Chỉ lưu trạng thái menu. Không có offset, hook, ghi nhớ hay
// logic bỏ qua kiểm tra nào ở đây. Mọi hiệu ứng trong game đều
// cần anh tự gắn địa chỉ đã dump đúng bản game vào mod.cpp.
#include <atomic>

struct CleanConfig {
    // Hiển thị
    int displayDpi = 1;      // 1..3, chỉ lưu giá trị
    int layout = 0;          // 0, 1, 2
    std::atomic<bool> watermark{true};
    // Chiến đấu
    std::atomic<bool> godMode{false};
    std::atomic<bool> oneHit{false};
    std::atomic<bool> infiniteMana{false};
    std::atomic<bool> superBuff{false};
    float attackMultiplier = 10.8f;  // xem SliderToAttackMultiplier
    std::atomic<bool> freezeEnemy{false};
    std::atomic<bool> autoWin{false};
    // Tài nguyên
    std::atomic<bool> infiniteCurrency{false};
    std::atomic<bool> infiniteTickets{false};
    std::atomic<bool> infiniteMeat{false};
    std::atomic<bool> infiniteSpirit{false};
    std::atomic<bool> infiniteBottles{false};
    std::atomic<bool> unlockModes{false};
    std::atomic<bool> boostRates{false};
    std::atomic<bool> infiniteEvents{false};
    std::atomic<bool> noAds{false};
    // Tốc độ & camera
    std::atomic<bool> simSpeedEnabled{false};
    float simSpeedValue = 3.0f;
    std::atomic<bool> gameSpeedEnabled{false};
    float gameSpeedValue = 2.0f;
    std::atomic<bool> cameraZoomEnabled{false};
    float cameraZoomValue = 1.34f;
    std::atomic<bool> fps120{false};
    std::atomic<bool> showInfo{false};
    // Chỉ là cờ, không có code thực thi đi kèm trong bản khung này.
    std::atomic<bool> antiCheatBypass{false};
    std::atomic<bool> bundleSpoof{false};
    // Trạng thái tick (chỉ dùng để ghi log khôi phục)
    bool wasSimSpeed = false;
    bool wasGameSpeed = false;
    bool wasZoom = false;
    float baseOrtho = 0.0f;
    float baseFov = 60.0f;
};

CleanConfig &GetCleanConfig();

// Ánh xạ thanh trượt 0..1 sang giá trị dùng trong game, theo đúng
// cách menu đã phân tích vẫn làm. Đây chỉ là công thức đổi số,
// không phải code sao chép.
inline float SliderToAttackMultiplier(float slider) { return slider * 49.0f + 1.0f; }
inline float SliderToSpeed(float slider) { return slider * 9.0f + 1.0f; }
inline float SliderToZoom(float slider) { return slider * 1.5f + 1.0f; }
inline float ClampSpeed(float value, float maxSpeed) {
    if (value < 0.5f) return 0.5f;
    if (value > maxSpeed) return maxSpeed;
    return value;
}
