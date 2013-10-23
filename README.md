# Apache Graphdat Plugin

#### Tracks the following metrics for [apache](http://httpd.apache.org/)

* APACHE_REQUESTS - The number of Apache `Accesses`
* APACHE_BYTES - Bytes transfered
* APACHE_BYTES_PER_REQUEST - Average bytes per request
* APACHE_CPU - CPU
* APACHE_BUSY_WORKERS - The count of busy workers
* APACHE_IDLE_WORKERS - The count of idle workers
* APACHE_BUSY_RATIO - The ratio of busy / total workers

#### Pre Reqs

To get statistics from apache, you need to enable the `server-stats` module.  In your `httpd.conf` add the following block

	<Location /server-status>
		SetHandler server-status
	</Location>

To make it a little more secure, add a username and password.  First by creating the file `sudo htpasswd -c /etc/apache2/passwd-server-status someusername`.   And then update your `httpd.conf` file with your newly created password file.

	<Location /server-status>
		SetHandler server-status
		AuthType basic
		AuthName "Apache status"
		AuthUserFile /etc/apache2/passwd-server-status
		Require valid-user
	</Location>

Once you make the update, reload your apache configuration
	`sudo service apache2 restart`

Check that your stats are coming through correctly by going to http://yourserver.com/server-status

### Installation & Configuration

* The `source` to prefix the display in the legend for the apache data.  It will default to the hostname of the server.
* The `url` is the full `server-status` URL from above that you just finished testing.
* If the `url` is password protected, what `username` and `password` combination did you use so we can make the call
