Amazon's excellent AWS IoT SDK for iOS does not support Mac OS X.  Since it is written in Objective-C, it seemed very natural to have an OS X port, but for reasons unknown Amazon has not made the necessary modifications to support OS X.

I have forked the Amazon aws-sdk-ios repository (https://github.com/aws-amplify/aws-sdk-ios) here: https://github.com/bdpdx/aws-sdk-ios and ported AWSCore, AWSIoT, and a few other frameworks to OSX.

Making the frameworks build on OS X wasn't too difficult, I just followed instructions from ColemanCDA here: http://colemancda.github.io/2015/02/11/universal-ios-osx-framework

Slightly more involved was making some API modifications to allow passing a certificate & private key (via PKCS12 file) to the MQTT routines vs. requiring they load from the keychain.  The setup process is documented in main.swift and is repeated here:

```
// The PKCS12 file is created from the AWS IoT certificate and private key as follows:
// openssl pkcs12 -export -in certificate.pem.crt -inkey private.pem.key -out awsiot-identity.p12
// The file *must* be created with a password or SecPKCS12Import() will fail.
// Then run `base64 awsiot-identity.p12` and copy the base 64 output into pkcs12IdentityDataBase64 below
```

To install, clone this project and run `init-submodule.sh`.

Some quirks:

- In case you didn't read the above, the PKCS12 file *must* be created with a password.
- You will need a valid signing identity to sign the various frameworks such as AWSCore/AWSIoT or the binary won't load.  For each framework you use, open the framework target settings in the AWSiOSSDKv2 project, enable automatic signing, and use your Mac OS X developer credentials from Apple.
- This project only shows how to connect to AWS IoT.  For MQTT operations such as subscribe/publish, see the AWS IoT Sample app here: https://github.com/awslabs/aws-sdk-ios-samples
