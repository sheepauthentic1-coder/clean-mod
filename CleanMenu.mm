// Menu UIKit tự viết, bố cục nhóm chức năng tương tự bản đã phân tích:
// Hiển thị, Chiến đấu, Tài nguyên, Tốc độ & Camera, Bảo vệ.
// Mọi công tắc và thanh trượt chỉ đổi giá trị trong CleanConfig,
// không có hiệu ứng trong game.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include "ModConfig.h"
#include <string>
#include <vector>

extern "C" void CleanShowMenu();

namespace {

UILabel *MakeLabel(NSString *text, CGFloat size, BOOL bold) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    label.textColor = UIColor.whiteColor;
    label.numberOfLines = 0;
    return label;
}

UIView *MakeSwitchRow(NSString *title, NSString *detail, std::atomic<bool> *flag) {
    UIView *row = [[UIView alloc] init];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *texts = [[UIStackView alloc] init];
    texts.axis = UILayoutConstraintAxisVertical;
    texts.spacing = 2;
    [texts addArrangedSubview:MakeLabel(title, 15, YES)];
    if (detail.length) [texts addArrangedSubview:MakeLabel(detail, 12, NO)];
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = flag->load();
    [sw addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        flag->store(sw.on);
    }] forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:texts];
    [stack addArrangedSubview:sw];
    [row addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:4],
        [stack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-4],
        [stack.topAnchor constraintEqualToAnchor:row.topAnchor constant:6],
        [stack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-6],
        [stack.heightAnchor constraintGreaterThanOrEqualToConstant:40],
    ]];
    return row;
}

UIView *MakeSliderRow(NSString *title, float sliderValue, float *configValue,
                      float (*map)(float), NSString *format) {
    UIView *row = [[UIView alloc] init];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *label = MakeLabel(title, 15, YES);
    UILabel *valueLabel = MakeLabel(@"", 13, NO);
    auto updateLabel = ^(float s) {
        *configValue = map(s);
        valueLabel.text = [NSString stringWithFormat:format, (double)*configValue];
    };
    updateLabel(sliderValue);
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = 0; slider.maximumValue = 1; slider.value = sliderValue;
    [slider addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        updateLabel(slider.value);
    }] forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:valueLabel];
    [stack addArrangedSubview:slider];
    [row addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:4],
        [stack.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-4],
        [stack.topAnchor constraintEqualToAnchor:row.topAnchor constant:6],
        [stack.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-6],
    ]];
    return row;
}

UIView *MakeSection(NSString *title, NSArray<UIView *> *rows) {
    UIStackView *section = [[UIStackView alloc] init];
    section.axis = UILayoutConstraintAxisVertical;
    section.spacing = 2;
    UILabel *header = MakeLabel(title, 13, YES);
    header.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    [section addArrangedSubview:header];
    for (UIView *row in rows) [section addArrangedSubview:row];
    UIView *sep = [[UIView alloc] init];
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    [sep.heightAnchor constraintEqualToConstant:1].active = YES;
    [section addArrangedSubview:sep];
    return section;
}

float InverseSpeed(float value) { return (value - 1.0f) / 9.0f; }
float InverseZoom(float value) { return (value - 1.0f) / 1.5f; }
float InverseAttack(float value) { return (value - 1.0f) / 49.0f; }

} // namespace

@interface CleanMenuManager : NSObject
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIButton *floatButton;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic) BOOL panelOpen;
@property (nonatomic) CGPoint dragStart;
@property (nonatomic) BOOL dragged;
+ (instancetype)shared;
- (void)show;
@end

@implementation CleanMenuManager

+ (instancetype)shared {
    static CleanMenuManager *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [[CleanMenuManager alloc] init]; });
    return s;
}

- (void)show {
    if (self.window) return;
    CleanConfig &cfg = GetCleanConfig();
    UIWindow *keyWindow = nil;
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) keyWindow = w;
    }
    CGRect bounds = keyWindow ? keyWindow.bounds : UIScreen.mainScreen.bounds;
    self.window = [[UIWindow alloc] initWithFrame:bounds];
    self.window.windowLevel = UIWindowLevelAlert + 1;
    self.window.backgroundColor = UIColor.clearColor;
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = UIColor.clearColor;
    self.window.rootViewController = vc;
    self.window.hidden = NO;

    self.floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatButton.frame = CGRectMake(bounds.size.width - 64, bounds.size.height * 0.4, 52, 52);
    [self.floatButton setTitle:@"M" forState:UIControlStateNormal];
    self.floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.floatButton.backgroundColor = [UIColor colorWithRed:0.15 green:0.45 blue:0.95 alpha:0.95];
    self.floatButton.layer.cornerRadius = 26;
    self.floatButton.layer.shadowOpacity = 0.4;
    [self.floatButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [self.floatButton addGestureRecognizer:pan];
    [vc.view addSubview:self.floatButton];

    CGFloat panelW = MIN(340, bounds.size.width - 24);
    CGFloat panelH = MIN(560, bounds.size.height - 60);
    self.panel = [[UIView alloc] initWithFrame:CGRectMake((bounds.size.width - panelW) / 2,
                                                          (bounds.size.height - panelH) / 2, panelW, panelH)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.96];
    self.panel.layer.cornerRadius = 16;
    self.panel.hidden = YES;
    self.panel.transform = CGAffineTransformMakeScale(0.9, 0.9);
    self.panel.alpha = 0;
    [vc.view addSubview:self.panel];

    UILabel *title = MakeLabel(@"Menu Mod (bản khung)", 17, YES);
    title.frame = CGRectMake(16, 12, panelW - 72, 24);
    [self.panel addSubview:title];
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"Đóng" forState:UIControlStateNormal];
    close.frame = CGRectMake(panelW - 64, 8, 56, 30);
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:close];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 48, panelW, panelH - 92)];
    [self.panel addSubview:scroll];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor constant:-14],
        [stack.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:4],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-4],
        [stack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor constant:-28],
    ]];

    UISegmentedControl *layoutSeg = [[UISegmentedControl alloc] initWithItems:@[@"Bố cục 1", @"Bố cục 2", @"Bố cục 3"]];
    layoutSeg.selectedSegmentIndex = cfg.layout;
    [layoutSeg addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        GetCleanConfig().layout = (int)layoutSeg.selectedSegmentIndex;
    }] forControlEvents:UIControlEventValueChanged];
    UIStepper *dpiStepper = [[UIStepper alloc] init];
    dpiStepper.minimumValue = 1; dpiStepper.maximumValue = 3; dpiStepper.value = cfg.displayDpi;
    [dpiStepper addAction:[UIAction actionWithHandler:^(__unused UIAction *a) {
        GetCleanConfig().displayDpi = (int)dpiStepper.value;
    }] forControlEvents:UIControlEventValueChanged];

    [stack addArrangedSubview:MakeSection(@"Hiển thị", @[
        MakeSwitchRow(@"Watermark", @"Hiện dấu nước trên menu", &cfg.watermark),
    ])];
    [stack addArrangedSubview:layoutSeg];
    [stack addArrangedSubview:dpiStepper];

    [stack addArrangedSubview:MakeSection(@"Chiến đấu", @[
        MakeSwitchRow(@"Bất tử", @"God mode", &cfg.godMode),
        MakeSwitchRow(@"Một đòn", @"One-hit", &cfg.oneHit),
        MakeSwitchRow(@"Mana vô hạn", @"", &cfg.infiniteMana),
        MakeSwitchRow(@"Super buff", @"", &cfg.superBuff),
        MakeSliderRow(@"Hệ số tấn công", InverseAttack(cfg.attackMultiplier), &cfg.attackMultiplier,
                      SliderToAttackMultiplier, @"Giá trị: %.1fx"),
        MakeSwitchRow(@"Đóng băng địch", @"", &cfg.freezeEnemy),
        MakeSwitchRow(@"Tự thắng", @"", &cfg.autoWin),
    ])];
    [stack addArrangedSubview:MakeSection(@"Tài nguyên", @[
        MakeSwitchRow(@"Tiền vô hạn", @"", &cfg.infiniteCurrency),
        MakeSwitchRow(@"Vé vô hạn", @"", &cfg.infiniteTickets),
        MakeSwitchRow(@"Thịt vô hạn", @"", &cfg.infiniteMeat),
        MakeSwitchRow(@"Tinh thần vô hạn", @"", &cfg.infiniteSpirit),
        MakeSwitchRow(@"Bình vô hạn", @"", &cfg.infiniteBottles),
        MakeSwitchRow(@"Mở chế độ", @"", &cfg.unlockModes),
        MakeSwitchRow(@"Tăng tỉ lệ", @"", &cfg.boostRates),
        MakeSwitchRow(@"Sự kiện vô hạn", @"", &cfg.infiniteEvents),
        MakeSwitchRow(@"Không quảng cáo", @"", &cfg.noAds),
    ])];
    [stack addArrangedSubview:MakeSection(@"Tốc độ & Camera", @[
        MakeSwitchRow(@"Bật tốc độ mô phỏng", @"", &cfg.simSpeedEnabled),
        MakeSliderRow(@"Tốc độ mô phỏng", InverseSpeed(cfg.simSpeedValue), &cfg.simSpeedValue,
                      SliderToSpeed, @"Giá trị: %.2fx"),
        MakeSwitchRow(@"Bật tốc độ game", @"", &cfg.gameSpeedEnabled),
        MakeSliderRow(@"Tốc độ game", InverseSpeed(cfg.gameSpeedValue), &cfg.gameSpeedValue,
                      SliderToSpeed, @"Giá trị: %.2fx"),
        MakeSwitchRow(@"Bật zoom camera", @"", &cfg.cameraZoomEnabled),
        MakeSliderRow(@"Zoom camera", InverseZoom(cfg.cameraZoomValue), &cfg.cameraZoomValue,
                      SliderToZoom, @"Giá trị: %.2fx"),
        MakeSwitchRow(@"120 FPS", @"", &cfg.fps120),
        MakeSwitchRow(@"Hiện thông tin", @"", &cfg.showInfo),
    ])];
    [stack addArrangedSubview:MakeSection(@"Bảo vệ (chỉ là cờ)", @[
        MakeSwitchRow(@"Bỏ qua kiểm tra", @"Chưa có code thực thi", &cfg.antiCheatBypass),
        MakeSwitchRow(@"Giả bundle id", @"Chưa có code thực thi", &cfg.bundleSpoof),
    ])];

    UILabel *footer = MakeLabel(@"Bản khung: công tắc chỉ đổi cờ, chưa có offset/hook/ghi nhớ.", 12, NO);
    footer.frame = CGRectMake(16, panelH - 36, panelW - 32, 28);
    [self.panel addSubview:footer];
    [self.window makeKeyAndVisible];
    // Trả lại key window cho game nếu có, cửa sổ menu vẫn hiển thị trên cùng.
    if (keyWindow) [keyWindow makeKeyWindow];
}

- (void)togglePanel {
    self.panelOpen = !self.panelOpen;
    self.panel.hidden = NO;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        self.panel.alpha = self.panelOpen ? 1 : 0;
        self.panel.transform = self.panelOpen ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(__unused BOOL done) {
        self.panel.hidden = !self.panelOpen;
    }];
}

- (void)onPan:(UIPanGestureRecognizer *)pan {
    CGPoint p = [pan locationInView:self.window.rootViewController.view];
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.dragStart = p; self.dragged = NO;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        if (fabs(p.x - self.dragStart.x) + fabs(p.y - self.dragStart.y) > 8) self.dragged = YES;
        if (self.dragged) {
            CGRect f = self.floatButton.frame;
            f.origin.x = MAX(0, MIN(p.x - 26, self.window.bounds.size.width - 52));
            f.origin.y = MAX(0, MIN(p.y - 26, self.window.bounds.size.height - 52));
            self.floatButton.frame = f;
        }
    } else if (pan.state == UIGestureRecognizerStateEnded && self.dragged) {
        CGRect f = self.floatButton.frame;
        CGFloat midX = f.origin.x + 26;
        f.origin.x = (midX < self.window.bounds.size.width / 2) ? 8 : self.window.bounds.size.width - 60;
        [UIView animateWithDuration:0.2 animations:^{ self.floatButton.frame = f; }];
    }
}

@end

extern "C" void CleanShowMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CleanMenuManager shared] show];
    });
}
