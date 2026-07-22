/**
 * RootViewController.m
 *
 * Root view controller implementation.
 * Displays the main interface with device list and settings.
 */

#import "RootViewController.h"
#import "DeviceListViewController.h"
#import "SettingsViewController.h"

@interface RootViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *settingsButton;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];

    // Title Label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"scrcpy-iOS";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:36];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    // Version Label
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.text = @"v1.0.0 - Remote Android Control";
    self.versionLabel.textColor = [UIColor grayColor];
    self.versionLabel.font = [UIFont systemFontOfSize:14];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.versionLabel];

    // Start Button
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startButton setTitle:@"Start Connection" forState:UIControlStateNormal];
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.startButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    self.startButton.layer.cornerRadius = 12;
    self.startButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.startButton addTarget:self action:@selector(startButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startButton];

    // Settings Button
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
    [self.settingsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.settingsButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    self.settingsButton.layer.cornerRadius = 12;
    self.settingsButton.titleLabel.font = [UIFont systemFontOfSize:16];
    self.settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.settingsButton addTarget:self action:@selector(settingsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.settingsButton];

    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Title
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100],

        // Version
        [self.versionLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],

        // Start Button
        [self.startButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.startButton.topAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:20],
        [self.startButton.widthAnchor constraintEqualToConstant:250],
        [self.startButton.heightAnchor constraintEqualToConstant:50],

        // Settings Button
        [self.settingsButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.settingsButton.topAnchor constraintEqualToAnchor:self.startButton.bottomAnchor constant:20],
        [self.settingsButton.widthAnchor constraintEqualToConstant:250],
        [self.settingsButton.heightAnchor constraintEqualToConstant:44],
    ]];
}

#pragma mark - Actions

- (void)startButtonTapped {
    NSLog(@"[scrcpy-iOS] Start button tapped");
    DeviceListViewController *deviceListVC = [[DeviceListViewController alloc] init];
    [self.navigationController pushViewController:deviceListVC animated:YES];
}

- (void)settingsButtonTapped {
    NSLog(@"[scrcpy-iOS] Settings button tapped");
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
