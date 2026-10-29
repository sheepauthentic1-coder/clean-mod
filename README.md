# Clean Mod — bản khung tự viết

Bản khung menu UIKit tự viết, bố cục nhóm chức năng tương tự bản đã
phân tích (Hiển thị, Chiến đấu, Tài nguyên, Tốc độ & Camera, Bảo vệ).

## Có gì

- Nút nổi "M", kéo thả, chạm để mở/đóng, tự dính mép khi thả.
- Panel cuộn với các công tắc, thanh trượt hệ số tấn công (1–50),
  tốc độ mô phỏng/game (1–10, kẹp 0,5–10), zoom camera (1–2,5),
  chọn bố cục và DPI.
- Tick skeleton trong `mod.cpp`: tính toán, kẹp giá trị, ghi log,
  khôi phục về 1.0 khi tắt. Không ghi vào bộ nhớ game.

## Giới hạn quan trọng

Đây chỉ là khung giao diện và lưu cờ. **Chưa có offset, hook hay
ghi nhớ nào.** Mọi hiệu ứng trong game đều cần anh tự gắn địa chỉ
đã dump đúng bản game (Il2CppDumper, `dump.cs` + RVA, cộng địa chỉ
gốc lúc chạy) vào các hàm `TODO` trong `mod.cpp`. Không có cổng key,
không có kiểm tra debugger, không có bảng mã hóa sao chép từ code
của bên khác.

## Build

GitHub Actions trên macOS tự build và đăng artifact `cleanmod-dylib`.
Build local trên macOS: `sh build_ios.sh`.
