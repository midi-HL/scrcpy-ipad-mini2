/**
 * SettingsViewController.m
 *
 * Settings interface for configuring video, display, and connection options.
 */

#import "SettingsViewController.h"
#import "SettingsManager.h"

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *items;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupData];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];
    self.title = @"Settings";

    // Navigation bar
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;

    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupData {
    self.sections = @[@"Video Settings", @"Display Settings", @"Connection Settings"];
    self.items = @[
        @[@{@"title": @"Resolution", @"type": @"picker", @"values": @[@"480p", @"720p", @"1080p", @"Original"], @"key": @"resolution"},
          @{@"title": @"Frame Rate", @"type": @"picker", @"values": @[@"15 FPS", @"24 FPS", @"30 FPS", @"60 FPS", @"Original"], @"key": @"framerate"},
          @{@"title": @"Bitrate", @"type": @"picker", @"values": @[@"1 Mbps", @"2 Mbps", @"4 Mbps", @"8 Mbps"], @"key": @"bitrate"}],
        @[@{@"title": @"Scaling Mode", @"type": @"picker", @"values": @[@"Fit", @"Stretch", @"Crop"], @"key": @"scaling"},
          @{@"title": @"Fullscreen", @"type": @"switch", @"key": @"fullscreen"}],
        @[@{@"title": @"ADB Port", @"type": @"text", @"key": @"adbport"},
          @{@"title": @"Auto Reconnect", @"type": @"switch", @"key": @"autoreconnect"}]
    ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.section][indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SettingsCell"];
    cell.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor grayColor];

    cell.textLabel.text = item[@"title"];

    SettingsManager *settings = [SettingsManager sharedManager];

    if ([item[@"type"] isEqualToString:@"picker"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSString *value = [settings valueForKey:item[@"key"]];
        cell.detailTextLabel.text = value ?: item[@"values"][0];
    } else if ([item[@"type"] isEqualToString:@"switch"]) {
        UISwitch *switchControl = [[UISwitch alloc] init];
        switchControl.on = [settings boolValueForKey:item[@"key"]];
        switchControl.tag = indexPath.section * 100 + indexPath.row;
        [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchControl;
    } else if ([item[@"type"] isEqualToString:@"text"]) {
        cell.detailTextLabel.text = [settings valueForKey:item[@"key"]] ?: @"5555";
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = self.items[indexPath.section][indexPath.row];

    if ([item[@"type"] isEqualToString:@"picker"]) {
        [self showPickerForItem:item atIndexPath:indexPath];
    } else if ([item[@"type"] isEqualToString:@"text"]) {
        [self showTextFieldForItem:item atIndexPath:indexPath];
    }
}

#pragma mark - Actions

- (void)switchChanged:(UISwitch *)sender {
    NSInteger section = sender.tag / 100;
    NSInteger row = sender.tag % 100;
    NSDictionary *item = self.items[section][row];

    SettingsManager *settings = [SettingsManager sharedManager];
    [settings setBool:sender.isOn forKey:item[@"key"]];
}

- (void)showPickerForItem:(NSDictionary *)item atIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item[@"title"]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *value in item[@"values"]) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:value style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            SettingsManager *settings = [SettingsManager sharedManager];
            [settings setValue:value forKey:item[@"key"]];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [alert addAction:action];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showTextFieldForItem:(NSDictionary *)item atIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item[@"title"]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        SettingsManager *settings = [SettingsManager sharedManager];
        textField.text = [settings valueForKey:item[@"key"]];
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        SettingsManager *settings = [SettingsManager sharedManager];
        [settings setValue:textField.text forKey:item[@"key"]];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

@end
