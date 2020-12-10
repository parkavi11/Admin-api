// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/stringutils;
import ballerina/http;

# Extract platform value from the provided user agent.
#
# + userAgent - The user agent string which consist client information.
# + return - The platform name extracted.
public function getPlatform(string userAgent) returns string|error {
    string[] userAgentSplit = stringutils:split(userAgent, " ");
    if (userAgentSplit.length() > 2) {
        string systemInfo = userAgentSplit[1];
        string[] systemInfoSplit = stringutils:split(systemInfo, "-");
        if (systemInfoSplit.length() >= 2) {
            string os = stringutils:replace(systemInfoSplit[0], "(", "");
            string platform = stringutils:replace(systemInfoSplit[1], ")", "");
            return os + "-" + platform;
        } else {
            error platformParseError = error("{update.tool}PlatformError", message = "unsupported platform for: " + userAgent);
            return platformParseError;
        }
    } else {
        error platformParseError = error("{update.tool}PlatformError", message = "unsupported platform for: " + userAgent);
        return platformParseError;
    }
}

# Extract tool version from the provided user agent.
#
# + userAgent - The user agent string which consist client information.
# + return - The tool version extracted.
public function getToolVersion(string userAgent) returns string|error {
    string[] userAgentSplit = stringutils:split(userAgent, " ");
    if (userAgentSplit.length() > 2) {
        string toolInfo = userAgentSplit[2];
        string[] toolInfoSplit = stringutils:split(toolInfo, "/");
        if (toolInfoSplit.length() >= 2) {
            return toolInfoSplit[1];
        } else {
            error toolParseError = error("{update.tool}PlatformError", message = "unsupported tool for: " + userAgent);
            return toolParseError;
        }
    } else {
        error toolParseError = error("{update.tool}PlatformError", message = "unsupported tool for: " + userAgent);
        return toolParseError;
    }
}

public function constructResponse(error|anydata data) returns http:Response {
    http:Response response = new;
    json resMsg = null;
    if (data is error) {
        resMsg = {
            msg: <string>data.detail()?.message
        };
        response.statusCode = 501;
    } else {
        var jsonConversionRet = json.constructFrom(data);
        if (jsonConversionRet is json) {
            resMsg = <@untainted> jsonConversionRet;
        }
    }
    response.setJsonPayload(resMsg);

    return response;
}
