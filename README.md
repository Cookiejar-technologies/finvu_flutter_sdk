# Finvu Flutter Mobile SDK Integration Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Accessing Finvu SDK APIs](#accessing-finvu-sdk-apis)
5. [Initialization](#initialization)
6. [Usage](#usage)
7. [APIs](#apis)
8. [PROGUARD-RULES (FOR ANDROID ONLY)](#proguard-rules)
9. [UX AA Sahamati Guidelines](#ux-aa-sahamati-guidelines)
10. [Code Guidelines](#code-guidelines)
11. [FinvuSDK Error Codes](#finvuSDK-errorodes)
12. [Frequently Asked Questions](#frequently-asked-questions)

## Introduction
Welcome to the integration guide for Finvu Flutter SDK! This document provides detailed instructions on integrating our SDK into your flutter application.

## Prerequisites
1. Flutter
    1. Dart SDK version supported is >=3.3.0 <4.0.0
    2. Flutter version supported is >=3.3.0
2. Android
    1. Min SDK version supported is 24
    2. Min kotlin version supported is 1.9.0
3. iOS
    1. Min iOS version supported is iOS 13

## Installation
1. Add `finvu_flutter_sdk` and `finvu_flutter_sdk_core` dependencies in your `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  finvu_flutter_sdk:
    git:
      url: https://github.com/Cookiejar-technologies/finvu_flutter_sdk.git
      path: client
      ref: 1.0.3 //Update with latest version
  finvu_flutter_sdk_core:
    git:
      url: https://github.com/Cookiejar-technologies/finvu_flutter_sdk.git
      path: core
      ref: 1.0.3 //Update with latest version
```

2. On android add the following repository to your project level `build.gradle` file. Note that you need to provide some github credentials.
```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        
        // Add these lines
        maven { 
            url 'https://maven.pkg.github.com/Cookiejar-technologies/finvu_android_sdk' 
            credentials {
                username = System.getenv("GITHUB_PACKAGE_USERNAME")
                password = System.getenv("GITHUB_PACKAGE_TOKEN")
            }
        }
    }
}
```

3. On android add the below in app level build.gradle file
```groovy
    defaultConfig {
        minSdkVersion 24
    }
```

4. On iOS add the following to your `Podfile`
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  ## Add these lines
  platform :ios, '16.0'
  pod 'FinvuSDK' , :git => 'https://github.com/Cookiejar-technologies/finvu_ios_sdk.git', :tag => '1.0.3' //Update with latest version

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    // Add these lines
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
```

## Accessing Finvu SDK APIs
`FinvuManager` class should be used to access the APIs on the SDK. `FinvuManager` class is a singleton, and can be accessed as follows:
```dart
final FinvuManager finvuManager = FinvuManager(); // Factory constructor will always return the same instance
```

## Initialization
Initialize the SDK in your application's entry point (eg. splash screen):
urls: 
UAT: "wss://webvwdev.finvu.in/consentapi"
PROD: "wss://wsslive.finvu.in/consentapi"
```dart
finvuManager.initialize(FinvuConfig(finvuEndpoint: "wss://webvwdev.finvu.in/consentapi"));
```

## Usage
Refer to the SDK documentation for detailed instructions on using various features and functionalities provided by the SDK. Below is the sequence diagram which includes SDK initialization, account linking and data fetch flows.
![sequence-diagram](docs/Sequence-diagram.png)

## APIs

### Connection Management
1. **Initialize with config**
Initialize API allows you to configure the finvuEndpoint. This is a way to configure the SDK to point to specific environments. 
```
    finvuManager.initialize(FinvuConfig(finvuEndpoint: "wss://wsslive.finvu.in/consentapi"));
```

2. **Connect** 
Finvu exposes websocket APIs that the sdk interacts with. Before making any other calls, connect method should be called. This is an async method, so await should be used to ensure its completion.
```
    await _finvuManager.connect();
```
3. **disconnect**
Disconnects from the Finvu AA server.
```
    await _finvuManager.disconnect();
```

4. **isConnected**
Checks if SDK is currently connected to Finvu AA server.
```
    await _finvuManager.isConnected();
```

### Authentication Flow
1. **Login with Consent Handle**
Initiates login process using either username or mobile number. Triggers OTP to user's registered mobile.
```dart
// Initial login or Resend OTP
var login = await finvuManager.loginWithUsernameOrMobileNumberAndConsentHandle(
    "USER_HANDLE", // MOBILE_NUMBER@finvu
    "MOBILE_NUMBER", 
    'CONSENT_HANDLE_ID', // handle id generated for the same user handle and mobile number
);
```

2. **Verify Login OTP**
Verifies login OTP and establishes authenticated session.
```dart
var handleInfo = await finvuManager.verifyLoginOtp(
    "123456", // OTP received
    otpReference // Reference from login response
);
```

Note: To resend OTP during login, simply call the loginWithUsernameOrMobileNumberAndConsentHandle API again with the same parameters.

3. **logout**
Logs out user and invalidates current session.
```dart
var handleInfo = await finvuManager.logout();
```

### FIP Management
1. **Fetch All FIP Options**
Retrieves list of all available Financial Information Providers (FIPs). and containes the FiTypes required by the FIP.
```dart
var fipList = await finvuManager.fipsAllFIPOptions();
```

2. **Fetch FIP Details**
Fetches detailed information about specific FIP ID received from the fipsAllFIPOptions API.
Also Contains identifiers required by the FIP for discovery.
```dart
var fipDetails = await finvuManager.fetchFIPDetails("FIP_ID");
```

### Account Discovery and Linking
1. **Discover Accounts**
```dart
Future<List<FinvuDiscoveredAccountInfo>> discoverAccounts(
    String fipId,
    List<String> fiTypes,
    List<FinvuTypeIdentifierInfo> identifiers)
```
Discovers user accounts with specified FIP using given identifiers.
```dart
final discoveredAccounts = await finvuManager.discoverAccounts(
    fipId,
    ["DEPOSIT", "RECURRING_DEPOSIT"],
    [
        FinvuTypeIdentifierInfo(
            category: "STRONG",
            type: "MOBILE",
            value: "9309107496"
        )
    ]
);
```

2. **Discover Accounts Async**
```dart
Future<List<FinvuDiscoveredAccountInfo>> discoverAccountsAsync(
    String fipId,
    List<String> fiTypes,
    List<FinvuTypeIdentifierInfo> identifiers,
  ) 
```
Discovers user accounts with specified FIP using given identifiers.
```dart
final discoveredAccounts = await finvuManager.discoverAccountsAsync(
    fipId,
    ["DEPOSIT", "RECURRING_DEPOSIT"],
    [
        FinvuTypeIdentifierInfo(
            category: "STRONG",
            type: "MOBILE",
            value: "9309107496"
        )
    ]
);
```

##### Difference Between `discoverAccounts` and `discoverAccountsAsync`

1. `discoverAccounts`
   - **Behavior**: Executes a synchronous request to discover accounts. The backend processes the request and returns the results immediately.  
   - **Use Case**: Use this method when you need real-time results and the account discovery process is expected to complete quickly.

2. `discoverAccountsAsync`
   - **Behavior**: Executes an asynchronous request to discover accounts. The backend processes the request in the background, and the results may take longer to return.  
   - **Use Case**: Use this method when the account discovery process might take more time, or when you can afford to wait for the results without blocking the user interface.

### Summary
- Use `discoverAccounts` for immediate results in scenarios where quick responses are critical.  
- Use `discoverAccountsAsync` for background processing when the discovery process is expected to take longer or can be deferred.

**The FiTypes required by the specific FIP is returned in the fipsAllFIPOptions API and the identifiers required for discovery of a certain  FIP is returned in the fetchFIPDetails API.**

**Note: Commonly User FiTypes are:**
DEPOSIT, TERM_DEPOSIT, TERM-DEPOSIT, RECURRING_DEPOSIT, INSURANCE_POLICIES, LIFE_INSURANCE, GENERAL_INSURANCE, MUTUAL_FUNDS, EQUITIES, GSTR1_3B, NPS, SIP, etc.

**Note: Examples of Identifiers for specific FiTypes**
1. Banks require Mobile Number as a strong type
```dart
[
        FinvuTypeIdentifierInfo(
            category: "STRONG",
            type: "MOBILE",
            value: "930910XXXX"
        )
]
```
2. Investments require same as bank the mobile as first identifier and additional weak PAN as a second identifier
```dart
[
        FinvuTypeIdentifierInfo(
            category: "STRONG",
            type: "MOBILE",
            value: "930910XXXX"
        ),
        FinvuTypeIdentifierInfo(
            category: "WEAK",
            type: "PAN",
            value: "DFKPGXXXXR"
        )
]
```
3. Insurance require same as bank the mobile as first identifier and additional needs DOB as a second identifier
```dart
[
        FinvuTypeIdentifierInfo(
            category: "STRONG",
            type: "MOBILE",
            value: "930910XXXX"
        ),
        FinvuTypeIdentifierInfo(
            category: "ANCILLARY",
            type: "DOB",
            value: "yyyy-MM-dd"
        )
]
```

2. **Link Accounts**
```dart
Future<FinvuAccountLinkingRequestReference> linkAccounts(
    FinvuFIPDetails fipDetails,
    List<FinvuDiscoveredAccountInfo> accounts)
```
Initiates account linking process for discovered accounts by passing a mapped FIP-Details and the user selected accounts.
```dart
final linkingReference = await finvuManager.linkAccounts(
    selectedFipDetails,
    selectedAccounts
);
```

3. **Confirm Account Linking**
```dart
Future<FinvuConfirmAccountLinkingInfo> confirmAccountLinking(
    FinvuAccountLinkingRequestReference requestReference,
    String otp)
```
Confirms account linking using received OTP.
```dart
var linkingInfo = await finvuManager.confirmAccountLinking(
    linkingReference,
    "123456" // OTP received
);
```

Note: To resend OTP during account linking, call the linkAccounts API again with the same parameters.

4. **Fetch Linked Accounts**
```dart
Future<List<FinvuLinkedAccountDetailsInfo>> fetchLinkedAccounts()
```
Retrieves list of all linked accounts for current user.
```dart
final existingLinkedAccounts = await finvuManager.fetchLinkedAccounts();
```

### Consent Management
1. **Get Consent Request Details**
```dart
Future<FinvuConsentRequestDetailInfo> getConsentRequestDetails(String handleId)
```
Retrieves details of consent requests raised by FIU.

2. **Approve Consent Request**
```dart
Future<FinvuProcessConsentRequestResponse> approveConsentRequest(
    FinvuConsentRequestDetailInfo consentInfo,
    List<FinvuLinkedAccountDetailsInfo> linkedAccounts)
```
Approves consent request for selected accounts.
```dart
await finvuManager.approveConsentRequest(
    consentRequestDetailInfo,
    selectedAccounts
);
```

3. **Deny Consent Request**
```dart
Future<FinvuProcessConsentRequestResponse> denyConsentRequest(
    FinvuConsentRequestDetailInfo consentInfo)
```
Denies consent request.
```dart
await finvuManager.denyConsentRequest(consentRequestDetailInfo);
```

## PROGUARD-RULES (**FOR ANDROID ONLY**)
For release build on android side due to minify and code obfuscation, to make them ignore the Finvu files please add these lines in your proguard rules file to keep them.

```
-keep class com.finvu.android.publicInterface.** { <fields>; }
-keep class com.finvu.android.models.** { <fields>; }
-keep class com.finvu.android.types.** { <fields>; }
```

## UX AA Sahamati Guidelines

While developing AA screens ,Please follow the UX AA guidelines by referring to the [link](https://workdrive.zohopublic.in/external/sheet/e0c838a03871e6258f44ff5b62042f2b89817a37c027e035c01e7d5ed9ce338f) 

## Code Guidelines

#### 1. Avoid Third-Party Imports, Code, or API Requests in the AA Journey
In the AA journey screens, ensure that **only AA flow-related code** is present. This means no third-party API requests that do not directly relate to the AA journey. 

#### 2. Do Not Store Data in Device Local Storage or Local DB
Avoid storing data in any local storage mechanisms like shared_preferences, flutter_secure_storage, or local databases (e.g., SQLite) in the AA screens.

#### 3. Clean Data and Instances at the End of the AA Journey
Ensure that all data is cleaned up when the AA journey ends. This includes closing any BLoC states and cleaning up objects like arrays or any other data that should not persist.

#### 4. Avoid Redundant Calls for finvuManager Methods
Repeatedly calling the same finvuManager methods can lead to unnecessary network requests, affecting performance and efficiency. Instead, use a global state to minimize redundant calls and optimize resource usage.

#### 5. Logout and Disconnect When the User Exits the AA Journey
Ensure that when the user exits the AA journey—whether in success, failure, or opt-out—you call the finvuManager.logout() and finvuManager.disconnect() methods to properly log out and disconnect from the WebSocket.

## Co-Creation Code push to repo  
We will create a GitHub repository named `fiu_journey_fiuname` and share it with you for pushing your AA journey code for review.

## Code Review Process  
Please create a feature branch from main always, once code is developed raise a PR for main with a wrapper around the AA journey so we can test and add us the reviewers.
Also attach screen recording of the AA journey screens from your mobile app for both iOS and Android platforms in PR Description.

## UI Review Process  
For each pull request created in the GitHub co-creation repository, please attach a screen recording of the AA journey screens from your mobile app for both iOS and Android platforms, where you are integrating the Finvu SDK. Additionally, kindly share these screen recordings in the designated communication channels (e.g., WhatsApp) for review.

## FinvuSDK Error Codes

1. **AUTH_LOGIN_RETRY** (Code: 1001)  
   Triggered when the login attempt fails, and the system retries the login process.

2. **AUTH_LOGIN_FAILED** (Code: 1002)  
   Occurs when the login attempt fails permanently (incorrect credentials, etc.).

3. **AUTH_FORGOT_PASSWORD_FAILED** (Code: 1003)  
   Raised when the request to reset the password fails.

4. **AUTH_LOGIN_VERIFY_MOBILE_NUMBER** (Code: 1004)  
   Indicates the need to verify the mobile number during the login process.

5. **AUTH_FORGOT_HANDLE_FAILED** (Code: 1005)  
   Raised when the handle (email/username) for the forgot password process fails.

6. **SESSION_DISCONNECTED** (Code: 8000)  
   Occurs when the user session is unexpectedly disconnected.

7. **SSL_PINNING_FAILURE_ERROR** (Code: 8001)  
   Triggered when SSL pinning fails during the network request.

8. **RECORD_NOT_FOUND** (Code: 8002)  
   Raised when the requested record is not found in the database.

9. **LOGOUT** (Code: 9000)  
   Triggered when the user successfully logs out of the application.

10. **GENERIC_ERROR** (Code: 9999)  
    A catch-all error for unspecified issues or unhandled exceptions.

## Frequently Asked Questions
Q. On Android I am getting the error `Class 'com.finvu.android.publicInterface.xxxxx' was compiled with an incompatible version of Kotlin. The binary version of its metadata is 1.9.0, expected version is 1.7.1.` or similar. How do I fix it?

A. Ensure that in your `settings.gradle` file, has the kotlin version set to 1.9.0
```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "7.3.0" apply false
    id "org.jetbrains.kotlin.android" version "1.9.0" apply false <--- check version here
}
```