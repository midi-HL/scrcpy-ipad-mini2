/**
 * DeviceListViewController.m
 *
 * Displays list of Android devices and manages connections.
 */

#import "DeviceListViewController.h"
#import "ConnectionViewController.h"
#import "SettingsManager.h"

@interface DeviceListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) UIButton *addDeviceButton;
@property (nonatomic, strong) UITextField *ipTextField;

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadDevices];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];
    self.title = @"Devices";

    // Navigation bar
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;

    // Add device button in navigation bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDeviceTapped)];
    self.navigationItem.rightBarButtonItem = addButton;

    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    // Add Device Section
    UIView *addDeviceView = [[UIView alloc] init];
    addDeviceView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    addDeviceView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:addDeviceView];

    // IP Text Field
    self.ipTextField = [[UITextField alloc] init];
    self.ipTextField.placeholder = @"Enter IP:Port (e.g., 192.168.1.100:5555)";
    self.ipTextField.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    self.ipTextField.textColor = [UIColor whiteColor];
    self.ipTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.ipTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.ipTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [addDeviceView addSubview:self.ipTextField];

    // Add Device Button
    self.addDeviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addDeviceButton setTitle:@"Add Device" forState:UIControlStateNormal];
    [self.addDeviceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addDeviceButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    self.addDeviceButton.layer.cornerRadius = 8;
    self.addDeviceButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addDeviceButton addTarget:self action:@selector(addDeviceConfirmed) forControlEvents:UIControlEventTouchUpInside];
    [addDeviceView addSubview:self.addDeviceButton];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        // Table View
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:addDeviceView.topAnchor],

        // Add Device View
        [addDeviceView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [addDeviceView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [addDeviceView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [addDeviceView.heightAnchor constraintEqualToConstant:100],

        // IP Text Field
        [self.ipTextField.topAnchor constraintEqualToAnchor:addDeviceView.topAnchor constant:10],
        [self.ipTextField.leadingAnchor constraintEqualToAnchor:addDeviceView.leadingAnchor constant:15],
        [self.ipTextField.trailingAnchor constraintEqualToAnchor:addDeviceView.trailingAnchor constant:-15],
        [self.ipTextField.heightAnchor constraintEqualToConstant:40],

        // Add Button
        [self.addDeviceButton.topAnchor constraintEqualToAnchor:self.ipTextField.bottomAnchor constant:10],
        [self.addDeviceButton.centerXAnchor constraintEqualToAnchor:addDeviceView.centerXAnchor],
        [self.addDeviceButton.widthAnchor constraintEqualToConstant:150],
        [self.addDeviceButton.heightAnchor constraintEqualToConstant:36],
    ]];
}

#pragma mark - Data

- (void)loadDevices {
    SettingsManager *settings = [SettingsManager sharedManager];
    self.devices = [[settings savedDevices] mutableCopy];
    [self.tableView reloadData];
}

- (void)saveDevices {
    SettingsManager *settings = [SettingsManager sharedManager];
    [settings setSavedDevices:self.devices];
}

#pragma mark - Actions

- (void)addDeviceTapped {
    [self.ipTextField becomeFirstResponder];
}

- (void)addDeviceConfirmed {
    NSString *ipText = self.ipTextField.text;
    if (ipText.length == 0) {
        [self showAlert:@"Error" message:@"Please enter an IP address"];
        return;
    }

    // Validate IP format
    if (![ipText containsString:@":"]) {
        ipText = [ipText stringByAppendingString:@":5555"];
    }

    // Add device
    NSDictionary *device = @{
        @"ip": ipText,
        @"name": [NSString stringWithFormat:@"Device %lu", (unsigned long)(self.devices.count + 1)],
        @"status": @"disconnected"
    };
    [self.devices addObject:device];
    [self saveDevices];
    [self.tableView reloadData];

    self.ipTextField.text = @"";
    [self.ipTextField resignFirstResponder];
}

- (void)connectToDevice:(NSDictionary *)device {
    ConnectionViewController *connectionVC = [[ConnectionViewController alloc] init];
    connectionVC.device = device;
    [self.navigationController pushViewController:connectionVC animated:YES];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DeviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }

    NSDictionary *device = self.devices[indexPath.row];
    cell.textLabel.text = device[@"name"];
    cell.detailTextLabel.text = device[@"ip"];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *device = self.devices[indexPath.row];
    [self connectToDevice:device];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.devices removeObjectAtIndex:indexPath.row];
        [self saveDevices];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
