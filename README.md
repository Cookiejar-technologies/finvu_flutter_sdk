# Finvu Flutter Mobile SDK Integration Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Accessing Finvu SDK APIs](#accessing-finvu-sdk-apis)
5. [Initialization](#initialization)
6. [Usage](#usage)
7. [APIs](#apis)
8. [Frequently Asked Questions](#frequently-asked-questions)

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
```
dependencies:
  flutter:
    sdk: flutter
  finvu_flutter_sdk:
    git:
      url: https://github.com/Cookiejar-technologies/finvu_flutter_sdk.git
      path: client
      ref: 1.0.1
  finvu_flutter_sdk_core:
    git:
      url: https://github.com/Cookiejar-technologies/finvu_flutter_sdk.git
      path: core
      ref: 1.0.1
```
2. On android add the following repository to your project level `build.gradle` file. Note that you need to provide some github credentials.
```
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
```
    defaultConfig {
        minSdkVersion 24
    }

```

4. On iOS add the following to your `Podfile`
```
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  ## Add these lines
  platform :ios, '16.0'
  pod 'FinvuSDK' , :git => 'https://github.com/Cookiejar-technologies/finvu_ios_sdk.git'

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
`FinvuManager` class that should be used to access the APIs on the SDK. `FinvuManager` class is a singleton, and can be access as follows:
```
final FinvuManager finvuManager = FinvuManager(); // Factory constructor will always return the same instance
```

## Initialization
Initialize the SDK in your application's entry point (eg. splash screen). SDK can be initialized using the the following method.
```
finvuManager.initialize(FinvuConfig(finvuEndpoint: "wss://wsslive.finvu.in/consentapi"));
```

## Usage
Refer to the SDK documentation for detailed instructions on using various features and functionalities provided by the SDK. Below is the sequence diagram which includes SDK initialization, account linking and data fetch flows.
![sequence-diagram](docs/Sequence-diagram.png)

## APIs

1. Initialize with config
Initialize API allows you to configure the finvuEndpoint. This is a way to configure the SDK to point to specific environments. 
```
    finvuManager.initialize(FinvuConfig(finvuEndpoint: "wss://wsslive.finvu.in/consentapi"));
```

2. Connect 
Finvu exposes websocket APIs that the sdk interacts with. Before making any other calls, connect method should be called. This is an async method, so await should be used to ensure its completion.
```
    await _finvuManager.connect();
```

3. Login with Consent Handle
Once the consent handle has been retrieved from the FIU server and we want to initiate the login flow for the user, it can be done in the following manner
```
var login = await _finvuManager.loginWithUsernameOrMobileNumberAndConsentHandle(
      "HANDLE_IF_ANY",
      null,
      'CONSENT_HANDLE_ID',
    );
```

4. Verify login otp
The login response contains the otp reference. Once user enters the otp, verification can be triggered in the following way - 
```
var login = await _finvuManager.verifyLoginOtp(
      otp,
      otpReference,
    );
```
Post login success, sdk will keep this session authenticated for the user and the rest of the methods can be triggered.

5. Fetch all FIP options
Use this method to get all FIP details where discovery flows can be triggered
```
    var fipList = await finvuManager.fipsAllFIPOptions();
```

6. Account discovery
In order to initiate discovery flow, you will need to get FIP details first. Get them for the selected FIP in the following way
```
var fetchFIPDetails = await finvuManager.fetchFIPDetails("FIP_ID");
```
Once FIPDetails are available, discovery can be made with the following step - 

```
final discoveredAccounts = await _finvuManager.discoverAccounts(
        fipDetails,
        fiTypes
        typeIdentifiers,
      );
```
FITypes describe the type of accounts that we want to discover, typeIdentifiers provides the identifiers to discover them with. Here's an example of what thay may look like - 
```json
    {
        "category": "STRONG",
        "type": "MOBILE",
        "value": "9309107496"
    }
```

7. Initiate account linking
Once accounts have been discovered, linking flow may be initiated. Multiple accounts can be linked at once. 
```
final linkingReference = await _finvuManager.linkAccounts(
        selectedFipDetails, // fipDetails that we fetched prior to the discovery call
        selectedAccounts // accounts from discovery that user has selected for linking
      );
```

8. Confirm account linking
On initiating account linking flow, an otp will be triggered by the FIP to the user. SDK will return a reference for this linking. Once user enters the top, linking can be confirmed by doing the following -

```
      await _finvuManager.confirmAccountLinking(
        linkingReference,
        otp,
      );
```

9. Fetch all linked accounts
All existing linked accounts for the user can be fetched in the following manner -
```
      final existingLinkedAccounts = await _finvuManager.fetchLinkedAccounts();
```

10. Consent flow
Once consent info is displayed to the user and user approves it, you can call the following method to convey the approval - 
```
await _finvuManager.approveConsentRequest(
        consentRequestDetailInfo,
        selectedAccounts,
    );
```

In case user denies the consent, call this method instead - 
```
    await _finvuManager.denyConsentRequest(consentRequestDetailInfo);
```

## Frequently Asked Questions
Q. On Android I am getting the error `Class 'com.finvu.android.publicInterface.xxxxx' was compiled with an incompatible version of Kotlin. The binary version of its metadata is 1.9.0, expected version is 1.7.1.` or similar. How do I fix it?

A. Ensure that in your `settings.gradle` file, has the kotlin version set to 1.9.0
```
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "7.3.0" apply false
    id "org.jetbrains.kotlin.android" version "1.9.0" apply false <--- check version here
}
```
