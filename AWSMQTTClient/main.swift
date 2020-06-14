//
//  main.swift
//  AWSMQTTClient
//
//  Created by Brian Doyle on 6/13/20.
//  Copyright © 2020 Balance Software. All rights reserved.
//

// This uses my port of aws-sdk-ios to MacOS here: https://github.com/bdpdx/aws-sdk-ios/tree/brian/port-to-macos

import AWSCore
import AWSIoT
import Foundation

struct Endpoint: Decodable {
    static var address: String {
        guard
            let output = Shell.run("aws iot describe-endpoint --endpoint-type iot:Data-ATS"),
            let endpoint = try? JSONDecoder().decode(Endpoint.self, from: output.stdout)
            else { fatalError("cannot get endpoint address") }

        return endpoint.endpointAddress
    }

    let endpointAddress: String
}

let AWS_IOT_DATA_MANAGER_KEY = "MyIotDataManager"
let AWS_IOT_MANAGER_KEY = "MyIotManager"
let AWS_REGION = AWSRegionType.USWest2
let IDENTITY_POOL_ID = "us-west-2:89d60045-2710-4be2-87a7-589caaa75377"
let IOT_ENDPOINT = "https://" + Endpoint.address
let POLICY_NAME = "AWSIoTSampleAppPolicy"

let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWS_REGION, identityPoolId: IDENTITY_POOL_ID)
let endpoint = AWSEndpoint(urlString: IOT_ENDPOINT)
let serviceConfiguration = AWSServiceConfiguration(
    region: AWS_REGION,
    endpoint: endpoint,
    credentialsProvider: credentialsProvider)!

AWSIoTDataManager.register(with: serviceConfiguration, forKey: AWS_IOT_DATA_MANAGER_KEY)

let dataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)

// The PKCS12 file is created from the AWS IoT certificate and private key as follows:
// openssl pkcs12 -export -in certificate.pem.crt -inkey private.pem.key -out awsiot-identity.p12
// The file *must* be created with a password or SecPKCS12Import() will fail.
// Then run `base64 awsiot-identity.p12` and copy the base 64 output into pkcs12IdentityDataBase64 below

let pkcs12IdentityDataBase64 = ""
let pkcs12IdentityData = Data(base64Encoded: pkcs12IdentityDataBase64)!

guard !pkcs12IdentityData.isEmpty else {
    fatalError("failed to decode pkcs12IdentityDataBase64")
}

let pkcs12IdentityDataPassphrase = "12345"
let clientId = UUID().uuidString

dataManager.connect(
    withClientId: clientId,
    cleanSession: true,
    pkcs12IdentityData: pkcs12IdentityData,
    pkcs12IdentityDataPassphrase: pkcs12IdentityDataPassphrase,
    statusCallback: mqttEventCallback)

func mqttEventCallback(_ status: AWSIoTMQTTStatus) {
    DispatchQueue.main.async {
        switch status {
        case .connecting:           print("connecting")
        case .connected:            print("connected")
        case .disconnected:         print("disconnected")
        case .connectionRefused:    print("connection refused")
        case .connectionError:      print("connection error")
        case .protocolError:        print("protocol error")
        default:                    print("unknown error")
        }
    }
}

while RunLoop.current.run(mode: .default, before: .distantFuture) { }

print("exiting")
