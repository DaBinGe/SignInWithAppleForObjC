# 苹果登录接入demo，参考官方swift代码转成objective-C

## 苹果要求：
有第三方登录的App，必须同时有苹果账号登录功能，并且入口最好放在其它第三方登录的前面。
参考文档[审核规范](https://developer.apple.com/cn/app-store/review/guidelines/)

## [官网介绍](https://developer.apple.com/cn/sign-in-with-apple/)

## 特性：
保密性：App不能获取AppleID相关信息；要求AppleID已双重认证。
稳定性：同个App，同个AppleID在不同手机得到授权的数据一样。
便捷：    直接使用手机登录密码、touch ID、face ID就可以授权登录。

## 硬件要求：
iOS 13系统的手机
macOS Mojave 10.14.4 or later的Mac电脑

## 软件要求：
Xcode 11 or it’s bate version
开发者账号生成对应证书、描述文件，证书的能力包含sign in with apple

接入流程：
![流程图](/Users/chenbinbin/Documents/SignInAppleChart.png)


## 登录服务类
* ASAuthorizationAppleIDProvider：获取授权登录状态
ASAuthorizationAppleIDProviderCredentialState

* ASAuthorizationAppleIDButton：苹果登录按钮，样式规范参考[苹果用户交互官方文档](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple/overview/)

* ASAuthorizationAppleIDRequest：授权请求，通过ASAuthorizationAppleIDProvider创建。需要它设置请求类型requestedScopes。

* ASAuthorizationController：授权弹窗，接收授权请求
ASAuthorizationAppleIDRequest，设置上下文代理来获取返回要显示在哪个window上；设置代理，获取授权登录返回结果。

* ASAuthorizationAppleIDCredential：授权AppID登录数据模型，用户ID、token等数据从此模型读取。
* ASPasswordCredential：授权密码登录数据模型。

## 下载[官方demo](https://developer.apple.com/documentation/authenticationservices/adding_the_sign_in_with_apple_flow_to_your_app)


参考博客 [Sign in with Apple
](https://www.jianshu.com/p/23b46dea2076)

