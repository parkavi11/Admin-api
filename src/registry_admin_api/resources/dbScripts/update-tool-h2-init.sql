/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

CREATE TABLE dependencies (
  name varchar(45) NOT NULL,
  PRIMARY KEY (name)
);

CREATE TABLE platforms (
  name varchar(45) NOT NULL,
  PRIMARY KEY (name)
);

INSERT INTO platforms (name) VALUES ('linux-64');
INSERT INTO platforms (name) VALUES ('macos-64');
INSERT INTO platforms (name) VALUES ('win-64');

CREATE TABLE dependencies_platforms (
  dependency_name varchar(45) NOT NULL,
  platform_name varchar(45) NOT NULL,
  location varchar(500) NOT NULL,
  PRIMARY KEY (dependency_name,platform_name)
);

CREATE TABLE distributions (
  id int(11) NOT NULL AUTO_INCREMENT,
  version varchar(20) NOT NULL,
  lts bit(1) DEFAULT NULL,
  type varchar(10) DEFAULT NULL,
  specVersion varchar(20) DEFAULT NULL,
  releaseDate varchar(45) DEFAULT NULL,
  remarks varchar(45) DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE distributions_dependencies (
  distribution_id int(11) NOT NULL,
  dependency_name varchar(45) NOT NULL,
  PRIMARY KEY (distribution_id,dependency_name)
);

CREATE TABLE distributions_platforms (
  distribution_id int(11) NOT NULL,
  platform_name varchar(45) NOT NULL,
  location varchar(500) NOT NULL,
  PRIMARY KEY (distribution_id,platform_name)
);

CREATE TABLE tools (
  id int(11) NOT NULL AUTO_INCREMENT,
  version varchar(20) NOT NULL,
  releaseDate varchar(45) DEFAULT NULL,
  remarks varchar(45) DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE tools_platforms (
  tool_id int(11) NOT NULL,
  platform_name varchar(45) NOT NULL,
  location varchar(500) NOT NULL,
  PRIMARY KEY (tool_id,platform_name)
);
