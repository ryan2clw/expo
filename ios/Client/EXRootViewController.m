// Copyright 2015-present 650 Industries. All rights reserved.

@import UIKit;

#import "EXAppDelegate.h"
#import "EXAppViewController.h"
#import "EXButtonView.h"
#import "EXHomeAppManager.h"
#import "EXKernel.h"
#import "EXAppLoader.h"
#import "EXKernelAppRecord.h"
#import "EXKernelAppRegistry.h"
#import "EXKernelDevKeyCommands.h"
#import "EXKernelLinkingManager.h"
#import "EXKernelServiceRegistry.h"
#import "EXMenuGestureRecognizer.h"
#import "EXMenuViewController.h"
#import "EXRootViewController.h"
#import "EXMenuWindow.h"

NSString * const kEXHomeDisableNuxDefaultsKey = @"EXKernelDisableNuxDefaultsKey";
NSString * const kEXHomeIsNuxFinishedDefaultsKey = @"EXHomeIsNuxFinishedDefaultsKey";

NS_ASSUME_NONNULL_BEGIN

@interface EXRootViewController () <EXAppBrowserController>

@property (nonatomic, strong) EXMenuViewController *menuViewController;
@property (nonatomic, assign) BOOL isMenuVisible;
@property (nonatomic, assign) BOOL isAnimatingAppTransition;
@property (nonatomic, strong) EXButtonView *btnMenu;
@property (nonatomic, strong, nullable) EXMenuWindow *menuWindow;
@property (nonatomic, strong, nullable) NSNumber *orientationBeforeShowingMenu;

@end

@implementation EXRootViewController

- (instancetype)init
{
  if (self = [super init]) {
    [EXKernel sharedInstance].browserController = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateMenuButtonBehavior)
                                                 name:kEXKernelDidChangeMenuBehaviorNotification
                                               object:nil];
    [self _maybeResetNuxState];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _btnMenu = [[EXButtonView alloc] init];
  _btnMenu.hidden = YES;
  [self.view addSubview:_btnMenu];
  EXMenuGestureRecognizer *menuGestureRecognizer = [[EXMenuGestureRecognizer alloc] initWithTarget:self action:@selector(_onMenuGestureRecognized:)];
  [((EXAppDelegate *)[UIApplication sharedApplication].delegate).window addGestureRecognizer:menuGestureRecognizer];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  _btnMenu.frame = CGRectMake(0, 0, 48.0f, 48.0f);
  _btnMenu.center = CGPointMake(self.view.frame.size.width - 36.0f, self.view.frame.size.height - 72.0f);
  [self.view bringSubviewToFront:_btnMenu];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  if (_isMenuVisible) {
    return [_menuViewController supportedInterfaceOrientations];
  }
  return [[EXKernel sharedInstance].visibleApp.viewController supportedInterfaceOrientations];
}

#pragma mark - EXViewController

- (void)createRootAppAndMakeVisible
{
  EXHomeAppManager *homeAppManager = [[EXHomeAppManager alloc] init];
  EXAppLoader *homeAppLoader = [[EXAppLoader alloc] initWithLocalManifest:[EXHomeAppManager bundledHomeManifest]];
  EXKernelAppRecord *homeAppRecord = [[EXKernelAppRecord alloc] initWithAppLoader:homeAppLoader appManager:homeAppManager];
  [[EXKernel sharedInstance].appRegistry registerHomeAppRecord:homeAppRecord];
  [self moveAppToVisible:homeAppRecord];
}

#pragma mark - EXAppBrowserController

- (void)moveAppToVisible:(EXKernelAppRecord *)appRecord
{
  [self _foregroundAppRecord:appRecord];

  // When foregrounding the app record we want to add it to the history to handle the edge case
  // where a user opened a project, then went to home and cleared history, then went back to a
  // the already open project.
  [self addHistoryItemWithUrl:appRecord.appLoader.manifestUrl manifest:appRecord.appLoader.manifest];

}

- (void)toggleMenuWithCompletion:(void (^ _Nullable)(void))completion
{
  [self setIsMenuVisible:!_isMenuVisible completion:completion];
}

- (void)setIsMenuVisible:(BOOL)isMenuVisible completion:(void (^ _Nullable)(void))completion
{
  if (!_menuViewController) {
    _menuViewController = [[EXMenuViewController alloc] init];
  }
  if (isMenuVisible != _isMenuVisible) {
    _isMenuVisible = isMenuVisible;

    if (isMenuVisible) {
      // Add menu view controller as a child of the root view controller.
      [_menuViewController willMoveToParentViewController:self];
      [_menuViewController.view setFrame:self.view.frame];
      [self.view addSubview:_menuViewController.view];
      [_menuViewController didMoveToParentViewController:self];

      // We need to force the device to use portrait orientation as it doesn't support landscape.
      // However, when removing it, we should set it back to the orientation from before showing the dev menu.
      _orientationBeforeShowingMenu = [[UIDevice currentDevice] valueForKey:@"orientation"];
      [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    } else {
      // Detach menu view controller from the root view controller.
      [_menuViewController willMoveToParentViewController:nil];
      [_menuViewController.view removeFromSuperview];
      [_menuViewController didMoveToParentViewController:nil];

      // Restore the original orientation that had been set before the dev menu was displayed.
      [[UIDevice currentDevice] setValue:_orientationBeforeShowingMenu forKey:@"orientation"];
    }
    // Ask the system to rotate the UI to device orientation that we've just set to fake value (see previous line of code).
    [UIViewController attemptRotationToDeviceOrientation];
  }
  if (completion) {
    completion();
  }
}

- (BOOL)isMenuVisible
{
  return _isMenuVisible;
}

- (void)showQRReader
{
  [self moveHomeToVisible];
  [[self _getHomeAppManager] showQRReader];
}

- (void)moveHomeToVisible
{
  __weak typeof(self) weakSelf = self;
  [self setIsMenuVisible:NO completion:^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf moveAppToVisible:[EXKernel sharedInstance].appRegistry.homeAppRecord];
      
      if (strongSelf.isMenuVisible) {
        [strongSelf setIsMenuVisible:NO completion:nil];
      }
    }
  }];
}

// this is different from Util.reload()
// because it can work even on an errored app record (e.g. with no manifest, or with no running bridge).
- (void)reloadVisibleApp
{
  if (_isMenuVisible) {
    [self setIsMenuVisible:NO completion:nil];
  }

  EXKernelAppRecord *visibleApp = [EXKernel sharedInstance].visibleApp;
  [[EXKernel sharedInstance] logAnalyticsEvent:@"RELOAD_EXPERIENCE" forAppRecord:visibleApp];
  NSURL *urlToRefresh = visibleApp.appLoader.manifestUrl;

  // Unregister visible app record so all modules get destroyed.
  [[[EXKernel sharedInstance] appRegistry] unregisterAppWithRecord:visibleApp];

  // Create new app record.
  [[EXKernel sharedInstance] createNewAppWithUrl:urlToRefresh initialProps:nil];
}

- (void)addHistoryItemWithUrl:(NSURL *)manifestUrl manifest:(NSDictionary *)manifest
{
  [[self _getHomeAppManager] addHistoryItemWithUrl:manifestUrl manifest:manifest];
}

- (void)getHistoryUrlForExperienceId:(NSString *)experienceId completion:(void (^)(NSString *))completion
{
  return [[self _getHomeAppManager] getHistoryUrlForExperienceId:experienceId completion:completion];
}

- (void)setIsNuxFinished:(BOOL)isFinished
{
  [[NSUserDefaults standardUserDefaults] setBool:isFinished forKey:kEXHomeIsNuxFinishedDefaultsKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isNuxFinished
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:kEXHomeIsNuxFinishedDefaultsKey];
}

- (void)appDidFinishLoadingSuccessfully:(EXKernelAppRecord *)appRecord
{
  // show nux if needed
  if (!self.isNuxFinished
      && appRecord == [EXKernel sharedInstance].visibleApp
      && appRecord != [EXKernel sharedInstance].appRegistry.homeAppRecord
      && !self.isMenuVisible) {
    [self setIsMenuVisible:YES completion:nil];
  }
  
  // check button availability when any new app loads
  [self _updateMenuButtonBehavior];
}

#pragma mark - internal

- (void)_foregroundAppRecord:(EXKernelAppRecord *)appRecord
{
  if (_isAnimatingAppTransition) {
    return;
  }
  EXAppViewController *viewControllerToShow = appRecord.viewController;
  EXAppViewController *viewControllerToHide;
  if (viewControllerToShow != self.contentViewController) {
    _isAnimatingAppTransition = YES;
    if (self.contentViewController) {
      viewControllerToHide = (EXAppViewController *)self.contentViewController;
    }
    if (viewControllerToShow) {
      [viewControllerToShow willMoveToParentViewController:self];
      [self.view addSubview:viewControllerToShow.view];
      [viewControllerToShow foregroundControllers];
    }

    __weak typeof(self) weakSelf = self;
    void (^transitionFinished)(void) = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        if (viewControllerToHide) {
          // backgrounds and then dismisses all modals that are presented by the app
          [viewControllerToHide backgroundControllers];
          [viewControllerToHide dismissViewControllerAnimated:NO completion:nil];
          [viewControllerToHide willMoveToParentViewController:nil];
          [viewControllerToHide.view removeFromSuperview];
          [viewControllerToHide didMoveToParentViewController:nil];
        }
        if (viewControllerToShow) {
          [viewControllerToShow didMoveToParentViewController:strongSelf];
          strongSelf.contentViewController = viewControllerToShow;
        }
        [strongSelf.view setNeedsLayout];
        strongSelf.isAnimatingAppTransition = NO;
        if (strongSelf.delegate) {
          [strongSelf.delegate viewController:strongSelf didNavigateAppToVisible:appRecord];
        }
      }
    };
    
    BOOL animated = (viewControllerToHide && viewControllerToShow);
    if (animated) {
      if (viewControllerToHide.contentView) {
        viewControllerToHide.contentView.transform = CGAffineTransformIdentity;
        viewControllerToHide.contentView.alpha = 1.0f;
      }
      if (viewControllerToShow.contentView) {
        viewControllerToShow.contentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
        viewControllerToShow.contentView.alpha = 0;
      }
      [UIView animateWithDuration:0.3f animations:^{
        if (viewControllerToHide.contentView) {
          viewControllerToHide.contentView.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
          viewControllerToHide.contentView.alpha = 0.5f;
        }
        if (viewControllerToShow.contentView) {
          viewControllerToShow.contentView.transform = CGAffineTransformIdentity;
          viewControllerToShow.contentView.alpha = 1.0f;
        }
      } completion:^(BOOL finished) {
        transitionFinished();
      }];
    } else {
      transitionFinished();
    }
  }
}

- (EXHomeAppManager *)_getHomeAppManager
{
  return (EXHomeAppManager *)[EXKernel sharedInstance].appRegistry.homeAppRecord.appManager;
}

- (void)_maybeResetNuxState
{
  // used by appetize: optionally disable nux
  BOOL disableNuxDefaultsValue = [[NSUserDefaults standardUserDefaults] boolForKey:kEXHomeDisableNuxDefaultsKey];
  if (disableNuxDefaultsValue) {
    [self setIsNuxFinished:YES];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kEXHomeDisableNuxDefaultsKey];
  }
}

- (void)_updateMenuButtonBehavior
{
  BOOL shouldShowButton = [[EXKernelDevKeyCommands sharedInstance] isLegacyMenuButtonAvailable];
  dispatch_async(dispatch_get_main_queue(), ^{
    self.btnMenu.hidden = !shouldShowButton;
  });
}

- (void)_onMenuGestureRecognized:(EXMenuGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded) {
    [[EXKernel sharedInstance] switchTasks];
  }
}

@end

NS_ASSUME_NONNULL_END
