Boundary Apache HTTP Server Plugin
----------------------------------
Collects metrics from a Apache HTTP server instance. See video [walkthrough](https://help.boundary.com/hc/articles/201991151).

### Prerequisites

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |    v    |    v    |  v   |


|  Runtime | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |    +    |        |      |

- [How to install node.js?](https://help.boundary.com/hc/articles/202360701)
- Apache HTTP Server must be configured to run the `server-stats` module. 

### Plugin Setup
- The Boundary Apache HTTP Server plugin depends on the `server-stats` module for collecting metrics. The sections below provide the procedures to enable and configure the `server-stats` module.

##### Enable the `server-status` Module

1. Modify the Apache HTTP Server `httpd.conf` by adding the following:
     ```xml
     <Location /server-status>
		SetHandler server-status
	 </Location>
     ```

##### Secure the EndPoint with a User Name and Password
1. Create as password file to secure the endpoint. The example shown here is using the path `/etc/httpd/my_password_file`.
     ```
     $ sudo htpasswd -c /etc/httpd/my_password_file
     ```
2. Enable authentication by modifying the `<Location/>` added previously as shown here :
     ```xml
	<Location /server-status>
		SetHandler server-status
		AuthType basic
		AuthName "Apache status"
		AuthUserFile /etc/httpd/my_password_file
		Require valid-user
	</Location>
    ```
3. Restart Apache HTTP server reload the `httpd.conf` configuration.
4. Verify that statistics are being collected by visiting http://yourserver.com/server-status

### Plugin Configuration Fields

|Field Name       |Description                                                                                  |
|:----------------|:--------------------------------------------------------------------------------------------|
|Server-Status URL|The URL endpoint of where the Apache HTPP server statistics are hosted.                      |
|Username         |If the URL is password protected, what username should the plugin use to authenticate        |
|Password         |If the URL is password protected, what password should the plugin use to authenticate        |
|Source           |Name identifying the specific instance of Apache HTTP server which is displayed in dashboards|

### Metrics Collected
Tracks the following metrics for [apache](http://httpd.apache.org/)

|Metric Name              |Description                                      |
|:------------------------|:------------------------------------------------|
|Apache Requests          |The number of Apache Accesses                    |
|Apache Total Bytes       |bytes transferred                                |
|Apache Bytes per Request |average bytes per request                        |
|Apache CPU               |                                                 |
|Apache Busy Workers      |the number of busy workers                       |
|Apache Idle Workers      |the number of idle workers                       |
|Apache busy to idle ratio|The ratio of busy workers / (busy + idle workers)|
