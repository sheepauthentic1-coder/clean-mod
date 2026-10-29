// Bản khung tự viết.
// Tick skeleton: chỉ tính toán và ghi log, KHÔNG ghi vào bộ nhớ game,
// KHÔNG gọi hàm game, KHÔNG hook. Để có hiệu ứng thật, anh phải tự
// điền địa chỉ đã dump đúng bản game (Il2CppDumper) vào phần TODO.
#include "ModConfig.h"
#include <cstdio>
#include <thread>
#include <chrono>
#include <cstdint>

extern "C" void CleanShowMenu();

static CleanConfig g_config;
CleanConfig &GetCleanConfig() { return g_config; }

// TODO (anh điền): trả về địa chỉ gốc của image game lúc chạy,
// ví dụ qua _dyld_get_image_header / _dyld_get_image_name.
// Bản khung trả về 0 nên mọi lần gọi game đều bị bỏ qua an toàn.
static std::uintptr_t GameImageBase() { return 0; }

// TODO (anh điền): từ tên phương thức trong dump.cs, trả về con trỏ
// hàm (địa chỉ gốc + RVA), hoặc qua API il2cpp của libil2cpp.
// Bản khung trả về nullptr.
static void *ResolveGameMethod(const char * /*methodName*/) { return nullptr; }

static void TickOnce(int tickCount) {
    CleanConfig &cfg = g_config;
    const float kMaxSpeed = 10.0f;

    // Tốc độ mô phỏng: kẹp giá trị, khôi phục về 1.0 khi tắt.
    if (cfg.simSpeedEnabled.load()) {
        float v = ClampSpeed(cfg.simSpeedValue, kMaxSpeed);
        std::printf("[clean-mod] sim speed -> %.2f (tick %d)\n", v, tickCount);
        cfg.wasSimSpeed = true;
        (void)ResolveGameMethod("FightSimulation_set_Speed");
    } else if (cfg.wasSimSpeed) {
        std::printf("[clean-mod] sim speed restore -> 1.0\n");
        cfg.wasSimSpeed = false;
    }

    // Tốc độ game: kẹp giá trị, khôi phục về 1.0 khi tắt.
    if (cfg.gameSpeedEnabled.load()) {
        float v = ClampSpeed(cfg.gameSpeedValue, kMaxSpeed);
        std::printf("[clean-mod] game speed -> %.2f (tick %d)\n", v, tickCount);
        cfg.wasGameSpeed = true;
        (void)ResolveGameMethod("Time_set_timeScale");
    } else if (cfg.wasGameSpeed) {
        std::printf("[clean-mod] game speed restore -> 1.0\n");
        cfg.wasGameSpeed = false;
    }

    // 120 FPS: chỉ ghi log mỗi 120 tick, giống nhịp trong bản đã phân tích.
    if (cfg.fps120.load() && (tickCount % 120 == 1)) {
        std::printf("[clean-mod] target frame rate requested: 120\n");
        (void)ResolveGameMethod("Application_set_targetFrameRate");
    }

    // Camera: ghi log hệ số, khôi phục khi tắt. Chưa đọc/ghi camera thật.
    if (cfg.cameraZoomEnabled.load()) {
        float ortho = cfg.baseOrtho > 0.1f ? cfg.baseOrtho * cfg.cameraZoomValue : cfg.cameraZoomValue;
        float fov = cfg.baseFov > 1.0f ? cfg.baseFov * cfg.cameraZoomValue : cfg.baseFov;
        if (fov > 130.0f) fov = 130.0f;
        std::printf("[clean-mod] camera ortho=%.2f fov=%.2f\n", ortho, fov);
        cfg.wasZoom = true;
        (void)ResolveGameMethod("Camera_set_orthographicSize");
        (void)ResolveGameMethod("Camera_set_fieldOfView");
    } else if (cfg.wasZoom) {
        std::printf("[clean-mod] camera restore ortho=%.2f fov=%.2f\n", cfg.baseOrtho, cfg.baseFov);
        cfg.wasZoom = false;
    }

    (void)GameImageBase();
}

__attribute__((constructor)) static void CleanModInit() {
    std::printf("[clean-mod] loaded (skeleton only, no game writes)\n");
    std::thread([] {
        CleanShowMenu();
        int tick = 0;
        while (true) {
            TickOnce(++tick);
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        }
    }).detach();
}
