var _os = require('os');
var _param = require('./param.json');
var _request = require('request');

var _IGNORE = ['Uptime', 'ReqPerSec', 'BytesPerSec', 'Scoreboard']; // Apache stats to ignore

var _httpOptions; // username/password options for the URL
var _previous = {}; // remember the previous poll data so we can provide proper counts

// At a minimum, we need a way to contact apache
if (!_param.url)
{
    console.error('To get statistics from Apache, a statistics URL is required');
    process.exit(-1);
}

// if there is no http or https, guess its http
if (_param.url.substring(0,7) !== 'http://' && _param.url.substring(0,8) !== 'https://')
    _param.url = 'http://' + _param.url;

// tell apache to make the output 'machine readable'
if (_param.url.slice(-5) !== '?auto')
    _param.url += '?auto';

// This this is a URL and we have a name and password, then we need to add an auth header
if (_param.username)
    _httpOptions = { auth: { user: _param.username, pass: _param.password, sendImmediately: true } };

// If we do not have a source, we prefix everything with the servers hostname
_param.source = (_param.source || _os.hostname()).trim();

// get the natural difference between a and b
function diff(a, b)
{
    if (a == null || b == null)
        return 0;
    else
        return Math.max(a - b, 0);
}

function handleError(err)
{
    console.error(err);
    process.exit(-1);
}

function poll(cb)
{
    // call apache to get the stats page
    _request.get(_param.url, _httpOptions, function(err, resp, body)
    {
        if (err)
            return handleError(err);
        if (resp.statusCode !== 200)
           return handleError(new Error('Apache returned with an error - recheck the URL and credentials that you provided'));
        if (!body)
           return handleError(new Error('Apache statistics return empty'));

        var current = {};
        var lines = body.split('\n');
        lines.forEach(function(line)
        {
            // skip over empty lines
            if (!line)
                return;

           // parse the record
            var data = line.split(':');
            var key = data[0].trim();
            var value = data[1];

            if (data.length !== 2 || _IGNORE.indexOf(key) !== -1)
                return;
            if (value == null || value === '')
                return;

            var fValue = parseFloat(value,10);
            if (fValue === 0 || fValue)
                current[key] = fValue;
            else
                current[key] = value.trim();
        });

        var totalWorkers =  (current['BusyWorkers'] + current['IdleWorkers']) || 1;
        var busyRatio = current['BusyWorkers'] / totalWorkers;

        console.log('APACHE_REQUESTS %d %s', diff(current['Total Accesses'], _previous['Total Accesses']), _param.source);
        console.log('APACHE_BYTES %d %s', diff(current['Total kBytes'], _previous['Total kBytes']), _param.source);
        console.log('APACHE_BYTES_PER_REQUEST %d %s', current['BytesPerReq'], _param.source);
        console.log('APACHE_CPU %d %s', current['CPULoad'], _param.source);
        console.log('APACHE_BUSY_WORKERS %d %s', current['BusyWorkers'], _param.source);
        console.log('APACHE_IDLE_WORKERS %d %s', current['IdleWorkers'], _param.source);
        console.log('APACHE_BUSY_RATIO %d %s', busyRatio, _param.source);

        _previous = current;

        setTimeout(poll, _param.pollInterval);
    });
}

poll();