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

import update_tool_model;
//import ballerina/config;
//import ballerina/io;
import ballerina/http;
//import ballerina/log;

//listener http:Listener adminEndPoint = new (3030, config = {
//    secureSocket: {
//        keyStore: {
//            path: config:getAsString("KEYSTORE_FILE", "/Library/Ballerina/distributions/jballerina-1.2.4/bre/security/ballerinaKeystore.p12"),
//            password: config:getAsString("KEYSTORE_PASSWORD", "ballerina")
//        }
//    }
//});

@http:ServiceConfig {
    basePath: "/admin"
}
service admin on new http:Listener(3031) {

    @http:ResourceConfig {
        methods: ["POST"],
        body: "distribution",
        path: "/distribution",
        consumes: ["application/json"]
    }
    resource function addDistribution(http:Caller caller, http:Request addDistributionsReq,
    update_tool_model:Distribution distribution) returns error? {
        http:Response addDistributionsRes = new;
        DBError | KeyNotFoundError? result = addDistribution(distribution);
        if (result is DBError) {
            addDistributionsRes.statusCode = http:STATUS_BAD_REQUEST;
            addDistributionsRes.setTextPayload(result.toString());
        } else if (result is KeyNotFoundError) {
            addDistributionsRes.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            addDistributionsRes.setTextPayload(result.toString());
        } else {
            addDistributionsRes.statusCode = http:STATUS_CREATED;
        //io:println("@@@@@@@@", config:getAsString("UPDATE_TOOL_DB_USERNAME"));
        }
        error? err = caller->respond(addDistributionsRes);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        body: "toolVersion",
        path: "/tool",
        consumes: ["application/json"]
    }
    resource function addTool(http:Caller caller, http:Request addToolsReq,
    update_tool_model:ToolVersion toolVersion) returns error? {
        http:Response addToolsRes = new;

        DBError | KeyNotFoundError? toolResult = addTool(toolVersion);
        if (toolResult is DBError) {
            addToolsRes.statusCode = http:STATUS_BAD_REQUEST;
            addToolsRes.setTextPayload(toolResult.toString());
        } else if (toolResult is KeyNotFoundError) {
            addToolsRes.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            addToolsRes.setTextPayload(toolResult.toString());
        } else {
            addToolsRes.statusCode = http:STATUS_CREATED;
        }
        error? err = caller->respond(addToolsRes);
    }

//@http:ResourceConfig {
//    methods: ["GET"],
//    path: "/distributions/latest/"
//}
//resource function getLatestDistributionsByVersion(http:Caller outboundEp,
//                                             http:Request getLatestDistributionByVersionReq)
//                                             returns error? {
//    http:Response|error res = trap getLatestDistributionsByVersion(<@untainted> getLatestDistributionByVersionReq);
//    error? err = ();
//    if (res is error) {
//        log:printError("error occured while getting latest distribution version.", err = res);
//        http:Response errorResponse = new;
//        errorResponse.setPayload("Not found");
//        errorResponse.statusCode = 404;
//        err = outboundEp->respond(errorResponse);
//    } else {
//        err = outboundEp->respond(res);
//    }
//}
}
