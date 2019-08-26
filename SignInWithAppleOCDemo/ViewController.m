//
//  ViewController.m
//  SignInWithAppleOCDemo
//
//  Created by 陈彬彬 on 2019/8/20.
//  Copyright © 2019 陈彬彬. All rights reserved.
//

#import "ViewController.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "SignInAppleDefine.h"

@interface ViewController ()
<
ASAuthorizationControllerPresentationContextProviding,
ASAuthorizationControllerDelegate
>

@property (nonatomic, weak)     UIButton *logoutBtn;
@property (nonatomic, weak)     ASAuthorizationAppleIDButton *loginBtn;

@end

@implementation ViewController

- (void)dealloc
{
    [self removeNotificationObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.view.backgroundColor = [UIColor whiteColor];
    [self getApppleIDCredentialState];
    [self addNotificationObserver];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initExistingAccountBtn];
//    [self performExistingAccountSetupFlows];
}

/// 获取认证状态
- (void)getApppleIDCredentialState
{
    NSString *userId = [NSUserDefaults.standardUserDefaults stringForKey:kAppleIDCurrentUserIdentifier];
    if (userId == nil) {
        userId = @"";
    }
    ASAuthorizationAppleIDProvider *privider = [ASAuthorizationAppleIDProvider new];
    [privider getCredentialStateForUserID:userId completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError * _Nullable error) {
        switch (credentialState) {
             case ASAuthorizationAppleIDProviderCredentialRevoked:
            {
                // 设置 -> Apple ID（设置列表第一行） -> 密码与安全性 -> 使用您Apple ID 的 App -> 编辑 -> 移除当前App。
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 显示登录按钮，
                    // 或者直接调起[self performExistingAccountSetupFlows]获取认证授权也可以
                    [self initLoginBtn:ASAuthorizationAppleIDButtonTypeContinue]; // weakself
                });
            }
                break;
            case ASAuthorizationAppleIDProviderCredentialAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initLogoutBtn]; // weakself
                });
            }
                break;
            case ASAuthorizationAppleIDProviderCredentialNotFound:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initLoginBtn:ASAuthorizationAppleIDButtonTypeSignIn]; // weakself
                });
            }
                break;
            case ASAuthorizationAppleIDProviderCredentialTransferred:
            {
                
            }
                break;
            default:
                break;
        }
    }];

}

/// 显示AppleID登录按钮
- (void)initLoginBtn:(ASAuthorizationAppleIDButtonType)buttonType
{
    /// 根据是否认证过、黑夜模式设置按钮样式
    ASAuthorizationAppleIDButton *btn = [ASAuthorizationAppleIDButton buttonWithType:buttonType style:ASAuthorizationAppleIDButtonStyleWhiteOutline];
    
    // default is {width:140, height:30}
    // 最小高度30，最小间距 高度/10，最小宽度140
    // 最大高度64
    // 设置圆角为 height/2，width=height，只显示苹果icon，但是不知道风险
    btn.frame = CGRectMake(10, 100, CGRectGetWidth(self.view.bounds) - 20, 50);
    [btn addTarget:self
            action:@selector(appleLoginButtonAction:)
  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.loginBtn = btn;
}

/// 显示退出登录按钮
- (void)initLogoutBtn
{
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(20, 100, CGRectGetWidth(self.view.bounds) - 20, 50)];
    [btn setTitle:@"sign out apple account" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(logoutButtonAction:)
  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    self.logoutBtn = btn;
}

- (void)initExistingAccountBtn
{
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(20, 200, CGRectGetWidth(self.view.bounds) - 20, 50)];
      [btn setTitle:@"exist accout request" forState:UIControlStateNormal];
      [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
      [btn addTarget:self
              action:@selector(performExistingAccountSetupFlows)
    forControlEvents:UIControlEventTouchUpInside];
      [self.view addSubview:btn];
}

#pragma mark - notification
- (void)addNotificationObserver
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didUserRevokedAppleSignInNotification:)
                                               name:ASAuthorizationAppleIDProviderCredentialRevokedNotification
                                             object:nil];
}

- (void)removeNotificationObserver
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
}

/// 用户移除此App的Apple ID登录权限
- (void)didUserRevokedAppleSignInNotification:(NSNotification*)notification
{
    // 调试没收到通知，估计是要能在后台运行才行
    // 需要App启动的时候获取ASAuthorizationAppleIDProviderCredentialState，检查是否被revoked了。
    [self logoutButtonAction:nil];
}

#pragma mark - action

/// 请求已认证过的账号信息
/// 不用取本地储存的uid，就能调起认证，重新安装App可用
- (void)performExistingAccountSetupFlows
{
    NSArray *requests = @[
        [ASAuthorizationAppleIDProvider new].createRequest,
        [ASAuthorizationPasswordProvider new].createRequest
    ];
    ASAuthorizationController *authVC = [[ASAuthorizationController alloc] initWithAuthorizationRequests:requests];
    authVC.delegate = self;
    authVC.presentationContextProvider = self;
    [authVC performRequests];
}

/// 请求登录
- (void)appleLoginButtonAction:(ASAuthorizationAppleIDButton*)sender
{
    ASAuthorizationAppleIDProvider *privider = [ASAuthorizationAppleIDProvider new];
    ASAuthorizationAppleIDRequest *request = privider.createRequest;
    request.requestedScopes = @[ASAuthorizationScopeFullName,ASAuthorizationScopeEmail];
    
    ASAuthorizationController *authVC = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request,
    [ASAuthorizationPasswordProvider new].createRequest]]; // pwd request is user for testing，delete it if neccessory.
    authVC.delegate = self;
    authVC.presentationContextProvider = self;
    [authVC performRequests];
}

/// 退出登录
- (void)logoutButtonAction:(UIButton*)sender
{
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kAppleIDCurrentUserIdentifier];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    [sender removeFromSuperview];
    
    [self initLoginBtn:ASAuthorizationAppleIDButtonTypeContinue];
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

/// 显示Apple ID登录界面的window
- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller
{
    return self.view.window;
}

#pragma mark - ASAuthorizationControllerDelegate
/// 失败回调
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error
{
    NSString *errorMsg = nil;
    switch (error.code) {
        case ASAuthorizationErrorCanceled:
            errorMsg = @"用户取消了授权请求";
            break;
        case ASAuthorizationErrorFailed:
            errorMsg = @"授权请求失败";
            break;
        case ASAuthorizationErrorInvalidResponse:
            errorMsg = @"授权请求响应无效";
            break;
        case ASAuthorizationErrorNotHandled:
            errorMsg = @"未能处理授权请求";
            break;
        case ASAuthorizationErrorUnknown:
            errorMsg = @"授权请求失败未知原因";
            break;
    }
    NSLog(@"%@", errorMsg);
}

/// Apple ID登录成功回调
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
{
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        ASAuthorizationAppleIDCredential *credential = authorization.credential;
        
        /// 唯一ID： 000319.f300c1c8ae3a40b2be115f5c1a04c079.1245
        ///         000319.f300c1c8ae3a40b2be115f5c1a04c079.1245
        /// 多次认证，同个App对应同个AppID，uid一样
        NSString *uid = credential.user;
        
        /// 当前用户具体信息，再次认证则为空
        NSPersonNameComponents *fullName = credential.fullName;
        
        /// AppID邮箱，再次认证则为空
        NSString *email = credential.email;


        NSString *authorizationCode = [[NSString alloc] initWithData:credential.authorizationCode encoding:NSUTF8StringEncoding]; // refresh token
        NSString *identityToken = [[NSString alloc] initWithData:credential.identityToken encoding:NSUTF8StringEncoding]; // access token
        
        /// 用于判断当前登录的苹果账号是否是一个真实用户
        ASUserDetectionStatus realUserStatus = credential.realUserStatus;

        
        [NSUserDefaults.standardUserDefaults setObject:uid
                                                forKey:kAppleIDCurrentUserIdentifier];
        [NSUserDefaults.standardUserDefaults synchronize];
        
        NSLog(@"user = %@,\nfull name = %@,\nemail = %@",uid,fullName,email);
        NSLog(@"auth code = %@,\ntoken = %@,\ndetection status = %ld",authorizationCode, identityToken, (long)realUserStatus);
    } else if ([authorization.credential isKindOfClass:[ASPasswordCredential class]]) {
        ASPasswordCredential *credential = authorization.credential;
        NSString *uid = credential.user;
        NSString *password = credential.password;
        NSLog(@"user = %@,\npassword = %@",uid,password);
    }
    [self.loginBtn removeFromSuperview];
    [self initLogoutBtn];
}

@end
