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

public type Distributions record {| 
    Distribution[] list;
    int totalCount;
|};

public type Distribution record {| 
    string 'version;
    boolean lts;
    string 'type;
    string specVersion;
    string location?;
    string name;
    string 'channel;
    Dependency[] dependencies;
    string prevVersion;
|};

public type Dependency record {| 
    string name;
|};

public type DistributionData record {| 
    int id;
    string 'version;
    string platform;
    boolean lts;
    string 'type;
    string specVersion;
    string releaseDate;
    string location;
    string remarks;
    string name;
    string 'channel;
|};

public type DistributionVersion record {|
    string 'version;
|};

public type LatestDistribution record {|
    int 'version;
    int latest;
|};

public type LatestDistributionVersions record {|
    int 'version;
|};

public type LatestToolVersion record {|
    string 'version;
|};

public type LatestDistributionVersion record {|
    string major?;
    string minor?;
    string patch?;
|};

public type DependencyData record {| 
    string location;
|};

public type ToolVersion record {|
    string 'version;
|};

public type ToolLocation record {|
    string location;
|};
