# logd

A simple delphi logger util. Can log to file and directly to windows if the application is a service, viewable via the Event viwer.

# TOC
- [logd](#logd)
- [TOC](#toc)
- [Usage](#usage)
- [Documentation](#documentation)
  - [Log level](#log-level)
  - [Log file period](#log-file-period)
  - [Services and the event viewer](#services-and-the-event-viewer)
- [Sample config file](#sample-config-file)

# Usage

A sample:

```pascal
uses 
    Ulog;

procedure someFunc();
begin
    // log is a global, acessible to every file that includes Ulog
    log := Tlog.Create(
        'myApplication',
        nil,
        TlogLevel.logLevelWarning,
        true,
        TlogFilePeriod.periodDaily
    );

    log.debug('This is some debug info');
    log.info('This is some info');
    log.warning('This is a warning');
    log.error('CRITICAL');
end;
```

The result:
```ini
[25/01/2023 17:16:41 174ms] [       ]: ---------------------------- BEGIN LOG ----------------------------
[25/01/2023 17:16:41 293ms] [WARNING]: This is a warning
[25/01/2023 17:16:41 294ms] [ERROR  ]: CRITICAL
```

# Documentation

## Log level

The log level can be set by the class member `Tlog.logLevel` or on the `Tlog.Create` method.

The higher the level the more verbose ethe log will be, use `TlogLevel.logLevelAll` to see all levels. Available ones are:

* `TlogLevel.logLevelError`
* `TlogLevel.logLevelWarning`
* `TlogLevel.logLevelInfo`
* `TlogLevel.logLevelDebug`
* `TlogLevel.logLevelAll`

## Log file period

The log file period can be set by the class member `Tlog.logFilePeriod` or on the `Tlog.Create` method.

Dictates if a new log file should be created on a time period basis, see the options:

* `TlogFilePeriod.periodHourly`: New log file every hour
* `TlogFilePeriod.periodDaily`: New log file everyday
* `TlogFilePeriod.periodWeekly`: New log file every week
* `TlogFilePeriod.periodMonthly`: New log file every month
* `TlogFilePeriod.periodYearly`: New log file every year
* `TlogFilePeriod.periodAlltime`: Just one log file to everything


## Services and the event viewer

Sometimes its conveninent to log to the windows machine instead of a file, or both!, because sometimes a service wont even be able to create a log file before crashing, for that you can always log to windows by passing a `TService` instance to the `Tlog.Create` call.

Logs can then be viewed under the `Event Viewer`, just hit the Windows key and search for the event viewer, then go to `Windows Logs > Applications`, then you should be able to see the logs for your service, as the `Source` column will have it's name.

# Sample config file

```ini
[log]
# level 4 = Debug. See "TlogLevel" enum
level=4
# boolean to log to a file or not
logfile=true
# boolean to log to windows or not
logToWindows=false
```