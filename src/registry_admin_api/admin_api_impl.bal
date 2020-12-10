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
import ballerina/config;
//import ballerina/http;
import ballerina/lang.'int;
import ballerina/log;
import ballerina/time;
//import hemikak/semver;
import ballerinax/java.jdbc;

final string DISTRIBUTION_LOCATION = "https://product-dist.ballerina.io/downloads/";
final string TOOL_LOCATION = "https://product-dist.ballerina.io/downloads/";
const BAD_REQUEST = "{registry/new_admin}DBError";
const INTERNAL_SERVER_ERROR = "{registry/new_admin}KeyNotFound";

type DBError error<BAD_REQUEST>;
type KeyNotFoundError error<INTERNAL_SERVER_ERROR>;

jdbc:Client dbClient = new ({
    url: "jdbc:mysql://localhost:3306/BALLERINA_UPDATE_TOOL_NEW?useSSL=false",
    username: "root",
    password: "rootuser",
    poolOptions: {maximumPoolSize: config:getAsInt("DB_MAX_POOL_SIZE", 100)},
    dbOptions: {useSSL: false}
});

function addDistribution(update_tool_model:Distribution distribution) returns DBError | KeyNotFoundError? {
    DBError | KeyNotFoundError er;
    int? dbDistributionId = ();
    log:printInfo(distribution.'version);
    log:printInfo(distribution.prevVersion.toString());
    // Insert distribution information in to table
    transaction {
        boolean checkVersion = validateDuplicatedDistributionEntry(distribution);
        if (checkVersion == false) {

            var returnDist = insertIntoDistributions(distribution);
            if (returnDist is error) {
                log:printError("cannot insert into distributions table ", returnDist);
            } else {
                // This is to work with mysql and h2.
                if (returnDist.generatedKeys.hasKey("GENERATED_KEY")) {
                    dbDistributionId = <int>returnDist.generatedKeys.get("GENERATED_KEY");
                //log:printInfo(dbDistributionId.toString());
                } else if (returnDist.generatedKeys.hasKey("ID")) {
                    dbDistributionId = <int>returnDist.generatedKeys.get("ID");
                //log:printInfo(dbDistributionId.toString());
                } else {
                    log:printError("cannot find updated key for newly added distribution: " + distribution.toString());
                    er = KeyNotFoundError(message = "cannot find updated key for newly added distribution.");
                }

                int distributionId = <int>dbDistributionId;
                string distributionLocation = DISTRIBUTION_LOCATION
                + distribution.'version + "/jballerina-" + distribution.'version
                + "/jballerina-" + distribution.'version + ".zip";
                var returnPlat = insertIntoDistributionPlatform(distributionId, "win-64", distributionLocation, "-win64");
                returnPlat = insertIntoDistributionPlatform(distributionId, "macos-64", distributionLocation, "-macos");
                returnPlat = insertIntoDistributionPlatform(distributionId, "linux-64", distributionLocation, "-linux");
                if (returnPlat is error) {
                    log:printError("unable to update table: DISTRIBUTIONS_PLATFORM", returnPlat);
                }
                //Iterate each dependency and insert them into table
                log:printInfo(dbDistributionId.toString());
                log:printInfo(distribution.toString());
                insertEachDependency(distribution, distributionId);

                //insertIntoLatests(distributionId, distribution);
            //if (retLatest is error) {
            //    log:printError("unable to update table: LATESTS", retLatest);
            //}
            }
        } else {
            log:printError("Distribution already exists: " + distribution.toString());
            er = DBError(message = "Bad Request");
        }
    } onretry {
        log:printInfo("Retrying transaction");
    } committed {
        log:printInfo("Successfully inserted into distributions: " + dbDistributionId.toString());
    } aborted {
        log:printError("cannot update the database.");
        er = DBError(message = "DB error found");
    }
    return er;
}

function validateDuplicatedDistributionEntry(update_tool_model:Distribution distribution) returns boolean {
    var distVersion = update_tool_model:DistributionVersion;
    string insertDist = distribution.'version;
    boolean checkVersion = false;
    string distributionVersion = "";
    var selectDistribution = dbClient->select("SELECT version FROM distributions ", update_tool_model:DistributionVersion);
    if (selectDistribution is table<update_tool_model:DistributionVersion>) {
        foreach var row in selectDistribution {
            distributionVersion = row.'version.toString();
            if (distributionVersion == insertDist) {
                checkVersion = true;
                break;
            }
        }
    } else {
        log:printError("cannot select version from distributions");
    }
    return checkVersion;
}

function insertIntoDistributions(update_tool_model:Distribution distribution) returns jdbc:UpdateResult | error {
    string releaseDate = checkpanic time:format(time:currentTime(), "yyyy-MM-dd");
    string remarks = "";
    var returnDist = dbClient->update("INSERT INTO distributions " +
    "(version, lts, type, specVersion, name, channel, releaseDate, remarks) "
    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    distribution.'version,
    distribution.lts,
    distribution.'type,
    distribution.specVersion,
    distribution.name,
    distribution.'channel,
    releaseDate,
    remarks);
    return returnDist;
}

function insertIntoDistributionPlatform(int distributionId, string platformName, string distributionLocation,
string platform) returns jdbc:UpdateResult | error {
    var retPlat = dbClient->update("INSERT INTO distributions_platforms " +
    "(distribution_id, platform_name, location) VALUES (?, ?, ?)",
    distributionId,
    platformName,
    distributionLocation + platform);
    if (retPlat is jdbc:UpdateResult) {
        log:printInfo("Inserted into distributions_platforms##");
    } else {
        log:printError("cannot insert into distributions_platforms###");
    }
    return retPlat;
}

function insertIntoDistributionsDependencies(int distributionId, string dependencyName) returns jdbc:UpdateResult | error {
    var ret = dbClient->update("INSERT INTO distributions_dependencies (distribution_id, dependency_name) " +
    "VALUES (?, ?)",
    distributionId,
    dependencyName);
    if (ret is jdbc:UpdateResult) {
        log:printInfo("Inserted into DISTRIBUTIONS_DEPENDENCIES##");
    } else {
        log:printError("cannot insert into DISTRIBUTIONS_DEPENDENCIES###");
        log:printError(ret.reason().toString());
        log:printError(ret.detail().toString());
    }
    return ret;
}

function insertEachDependency(update_tool_model:Distribution distribution, int distributionId) {
    foreach update_tool_model:Dependency dependency in distribution.dependencies {
        // Insert distribution dependency
        var ret = insertIntoDistributionsDependencies(distributionId, dependency.name);
        log:printInfo(dependency.name.toString());
        log:printInfo(distributionId.toString());
        if (ret is jdbc:UpdateResult) {
            log:printInfo("Inserted into DISTRIBUTIONS_DEPENDENCIES");
        } else {
            log:printError("cannot insert into DISTRIBUTIONS_DEPENDENCIES");
            log:printError(ret.reason().toString());
            log:printError(ret.detail().toString());
        }
    }
}

function insertIntoLatests(int distributionId, update_tool_model:Distribution distribution) {
    string previousVersion = distribution.prevVersion;
    var retLatest = dbClient->update("INSERT INTO latests (version, latest) " +
    "VALUES (?, ?)",
    distributionId,
    distributionId);
    if (retLatest is jdbc:UpdateResult) {
        log:printInfo("Inserted into LATESTS");
    } else {
        log:printError("cannot insert into LATESTS");
        log:printError(retLatest.reason().toString());
        log:printError(retLatest.detail().toString());
    }

    var retPrevVersionId = dbClient->select("SELECT id from DISTRIBUTIONS where version=?", update_tool_model:Distribution, previousVersion);
    if (retPrevVersionId is table<update_tool_model:DistributionVersion>) {
        string prevIDStr = retPrevVersionId.toString();
        int | error prevID = 'int:fromString(prevIDStr);
        log:printInfo(prevIDStr);
        if (prevID is int) {
            var retLatestPrevId = dbClient->select("SELECT latest from LATESTS where latest=?", update_tool_model:LatestDistribution, prevID);
            if (retLatestPrevId is table<update_tool_model:LatestDistributionVersions>) {
                var retUpdate = dbClient->update("UPDATE LATESTS SET latest=? WHERE version=?", distributionId, prevID);
            } else {
                log:printError("cannot select latest from LATESTS");
            }
        } else {
            log:printInfo("prev id is error");
        }
    } else {
        log:printError("cannot select id from DISTRIBUTIONS for given previous version");
        //log:printError(retPrevVersionId.reason().toString());
        //log:printError(retPrevVersionId.detail().toString());
    }
}

function addTool(update_tool_model:ToolVersion toolVersion) returns DBError | KeyNotFoundError? {
    DBError | KeyNotFoundError er;
    boolean checkVersion = validateDuplicatedToolVersion(toolVersion);
    int? dbToolId = ();
    transaction {
        if (checkVersion == false) {
            var returnTools = insertIntoTools(toolVersion);
            if (returnTools is error) {
                log:printError("cannot insert into TOOLS table", returnTools);
            } else {
                // This is to work with mysql and h2.
                if (returnTools.generatedKeys.hasKey("GENERATED_KEY")) {
                    dbToolId = <int>returnTools.generatedKeys.get("GENERATED_KEY");
                } else if (returnTools.generatedKeys.hasKey("ID")) {
                    dbToolId = <int>returnTools.generatedKeys.get("ID");
                } else {
                    log:printError("cannot find updated key for newly added tool: " + toolVersion.toString());
                    er = KeyNotFoundError(message = "cannot find updated key for newly added toolVersion.");
                }
                int toolId = <int>dbToolId;
                string toolLocation = TOOL_LOCATION
                + toolVersion.'version + "/jballerina-" + toolVersion.'version;
                var returnToolsPlat = insertIntoToolsPlatform(toolId, "win-64", toolLocation);
                returnToolsPlat = insertIntoToolsPlatform(toolId, "macos-64", toolLocation);
                returnToolsPlat = insertIntoToolsPlatform(toolId, "linux-64", toolLocation);
                if (returnToolsPlat is error) {
                    log:printError("cannot insert into TOOLS_PLATFORMS table", returnToolsPlat);
                }
            }
        } else {
            log:printError("Tool version already exists: " + toolVersion.toString());
            er = DBError(message = "Bad Request");
        }
    } onretry {
        log:printInfo("Retrying transaction");
    } committed {
        log:printInfo("Successfully inserted into distributions: " + dbToolId.toString());
    } aborted {
        log:printError("cannot update the database.");
        er = DBError(message = "DB error found");
    }
    return er;
}

function insertIntoTools(update_tool_model:ToolVersion toolVersion) returns jdbc:UpdateResult | error {
    string releaseDate = checkpanic time:format(time:currentTime(), "yyyy-MM-dd");
    string remarks = "";
    var returnTools = dbClient->update("INSERT INTO tools (version, releaseDate, remarks) " +
    "VALUES (?, ?, ?)",
    toolVersion.'version,
    releaseDate,
    remarks);
    return returnTools;
}

function validateDuplicatedToolVersion(update_tool_model:ToolVersion toolVersion) returns boolean {
    string insertTool = toolVersion.'version;
    boolean checkVersion = false;
    string latestToolVersion = "";
    var selectToolVersion = dbClient->select("SELECT version FROM tools ", update_tool_model:ToolVersion);
    if (selectToolVersion is table<update_tool_model:ToolVersion>) {
        foreach var row in selectToolVersion {
            latestToolVersion = row.'version.toString();
            if (latestToolVersion == insertTool) {
                checkVersion = true;
                break;
            }
        }
    } else {
        log:printError("cannot select version from tools");
    }
    return checkVersion;
}

function insertIntoToolsPlatform(int toolId, string platformName, string toolLocation) returns jdbc:UpdateResult | error {
    var returnToolsPlat = dbClient->update("INSERT INTO tools_platforms (tool_id, platform_name, location) " +
    "VALUES (?, ?, ?)",
    toolId,
    platformName,
    toolLocation);
    return returnToolsPlat;
}

function getDistributionVersions(string platformName) returns update_tool_model:DistributionVersion[] | error {
    update_tool_model:DistributionVersion[] distributionVersions = [];
    var selectDist = dbClient->select("SELECT d.version"
    + " FROM distributions d"
    + " JOIN distributions_platforms dp ON d.id = dp.distribution_id "
    + " JOIN platforms p ON p.name = dp.platform_name"
    + " WHERE dp.platform_name = ?",
    update_tool_model: DistributionVersion, platformName);
    if (selectDist is table<update_tool_model:DistributionVersion>) {
        foreach update_tool_model:DistributionVersion row in selectDist {
            distributionVersions[distributionVersions.length()] = row;
        }
        return <@untainted>distributionVersions;
    } else {
        return <@untainted><error>selectDist;
    }
}

//
//public function getLatestDistributionsByVersion(http:Request getLatestDistributionReq, string platformName) returns semver:Version {
//    string|() _type = getLatestDistributionReq.getQueryParamValue("type");
//    string|() _version = getLatestDistributionReq.getQueryParamValue("version");
//    semver:Version[] patchVersion = [];
//    if (_version is ()) {
//        log:printError("error getting version from request parameters.");
//        //getLatestDistributionRes.statusCode = 501;
//        //getLatestDistributionRes.setPayload("error getting version from request parameters.");
//        //return getLatestDistributionRes;
//    }
//    update_tool_model:DistributionVersion[]|error distributionVersions= getDistributionVersions(platformName);
//    if (distributionVersions is update_tool_model:DistributionVersion[]) {
//        semver:Version[] versions = [];
//        foreach update_tool_model:DistributionVersion dv in distributionVersions {
//            versions[versions.length()] = <semver:Version>semver:convertToVersion(dv.'version);
//        }
//        semver:Version userVersion = <semver:Version>semver:convertToVersion(<string>_version);
//        if (_type is string) {
//            string typeLower = _type.toLowerAscii();
//            if (typeLower == "patch") {
//                string semverRange = string `${userVersion.major}.${userVersion.minor}.x`;
//                patchVersion = <semver:Version>semver:findLatestInRange(semverRange, versions);
//                update_tool_model:LatestDistributionVersion lv = { patch: semver:toString(patchVersion)};
//                //getLatestDistributionRes.setJsonPayload(<@untainted> <json>json.constructFrom(lv));
//                //return getLatestDistributionRes;
//                return patchVersion;
//            }
//        }
//
//        string patchSemverRange = string `${userVersion.major}.${userVersion.minor}.x`;
//        patchVersion =  <semver:Version>semver:findLatestInRange(patchSemverRange, versions);
//
//        update_tool_model:LatestDistributionVersion lv = { patch: semver:toString(patchVersion)};
//        //getLatestDistributionRes.setJsonPayload(<@untainted> <json>json.constructFrom(lv));
//        //return getLatestDistributionRes;
//        return patchVersion;
//    }
//    error err = <error>distributionVersions;
//    log:printError("unable to get distribution versions from db", err = err);
//    return patchVersion;
//    //getLatestDistributionRes.statusCode = 500;
//    //json errorMsg = {
//    //    message: "internal server error occurred. please contact administrator."
//    //};
//    //getLatestDistributionRes.setJsonPayload(errorMsg);
//    //return getLatestDistributionRes;
//}
