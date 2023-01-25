unit Ulog;

interface

uses
    System.SysUtils,
    System.Classes,
    System.IOUtils,
    Winapi.Windows,
    Vcl.SvcMgr;

type
    // the log level, the lower the more strict, the higher, more information
    TlogLevel = (
        logLevelNone = 0,
        logLevelError,
        logLevelWarning,
        logLevelInfo,
        logLevelApp,
        logLevelDebug,
        logLevelAll = MAXWORD
    );

    // period of logging for log files
    TlogFilePeriod = (
        periodHourly = 0,
        periodDaily,
        periodWeekly,
        periodMonthly,
        periodYearly,
        periodAlltime
    );

    // log class
    Tlog = class
        private
        logToFile: Boolean;
        logStream: TFileStream;
        logWriter: TStreamWriter;
        logName: string;
        lastPeriod: TDateTime;
        service: TService;

        procedure rawLog(name: string; str: string; level: TlogLevel);
        procedure probeLogfile();

        public
        logLevel: TlogLevel;
        period: TlogFilePeriod;

        // create a new logger, wich can output to a logFile and the windows event viewer
        // if svc is provided and not "nil", the log calls are logged to the windows event viewer
        // if lofToFile is true, the log calls will be logged to the specified file
        // log level defines a filter for the calls, the lower the more strict, the higher, more loose. See the TlogLevel enum
        constructor Create(logFilename: string; svc: TService = nil; logLevel: TlogLevel = logLevelInfo; logToFile: Boolean = true; period: TlogFilePeriod = periodAlltime);
        destructor Destroy(); override;

        // log calls, in order of importance, defined by logLevel, except force, wich will always be logged
        procedure force(str: string);
        procedure error(str: string);
        procedure warning(str: string);
        procedure info(str: string);
        procedure app(appName: string; str: string);
        procedure debug(str: string);
    end;

var
    // global log object used to log messages
    log: Tlog;

implementation

uses
    System.DateUtils;

const
    // date format for the entries in the log file
    datetimefmt = 'dd/mm/yyyy hh:nn:ss" "zzz"ms"';
    // file name format
    logfilenamefmt = '%s-%s.log';
    // file name date format
    logfilenamedatefmt = 'dd-mm-yyyy-hh-nn-ss';
    // log header/leader for each log entry 
    logLeaderFmt = '[%s] [%-7s]: %s';

procedure Tlog.probeLogfile();
begin
    if((logToFile = false) or (logName.IsEmpty())) then exit;                                                               // if no log file

    var createNew: Boolean;

    var time := Now();
    case period of 
        TlogFilePeriod.periodHourly:    createNew := HoursBetween(time, lastPeriod) > 1;
        TlogFilePeriod.periodDaily:     createNew := DaysBetween(time, lastPeriod) > 1;
        TlogFilePeriod.periodWeekly:    createNew := WeeksBetween(time, lastPeriod) > 1;
        TlogFilePeriod.periodMonthly:   createNew := MonthsBetween(time, lastPeriod) > 1;
        TlogFilePeriod.periodYearly:    createNew := YearsBetween(time, lastPeriod) > 1;
        TlogFilePeriod.periodAlltime:   createNew := false;
        else                            createNew := false;
    end;

    if(createNew) then                                                                                                  // if required
    begin
        lastPeriod := Now();
        if logWriter <> nil then logWriter.Destroy();                                                                   // close old logfile stream and writter
        if logStream <> nil then logStream.Destroy();
        
        var name := Format(logfilenamefmt, [logName, FormatDateTime(logfilenamedatefmt, time)]);                        // new filename
        
        if(FileExists(name)) then                                                                                       // open or create     
            logStream := TFileStream.Create(name, fmOpenReadWrite or fmShareDenyWrite)
        else
            logStream := TFileStream.Create(name, fmCreate or fmShareDenyWrite);

        logStream.Seek(0, soFromEnd);                                                                                   // go to the stream end
        logWriter := TStreamWriter.Create(logStream);
        logWriter.AutoFlush := true;
    end;
end;

constructor Tlog.Create(logFilename: string; svc: TService = nil; logLevel: TlogLevel = logLevelInfo; logToFile: Boolean = true; period: TlogFilePeriod = periodAlltime);
begin
    inherited Create();
    try
        self.logToFile := logToFile;
        self.period := period;
        self.logName := logFilename;
        self.service := svc;
        self.logLevel := logLevel;

        probeLogfile();

        force('------------------------------------------- BEGIN LOG -------------------------------------------');
    except
        on E: exception do raise;
    end;
end;

destructor Tlog.Destroy();
begin
    inherited Destroy();

    if(logToFile) then
    begin
        logWriter.Destroy();
        logStream.Destroy();
    end;
end;

procedure Tlog.info(str: string);
begin
    rawLog('INFO', str, TlogLevel.logLevelInfo);
end;

procedure Tlog.error(str: string);
begin
    rawLog('ERROR', str, TlogLevel.logLevelError);
end;

procedure Tlog.warning(str: string);
begin
    rawLog('WARNING', str, TlogLevel.logLevelWarning);
end;

procedure Tlog.debug(str: string);
begin
    rawLog('DEBUG', str, TlogLevel.logLevelDebug);
end;

procedure Tlog.app(appName: string; str: string);
begin
    var msg: string;
    if(logLevel < TlogLevel.logLevelApp) then exit;

    msg := Format('[%s] [APP    ]: [%s] %s', [FormatDateTime(datetimefmt, Now()), appName, str]);

    if(logToFile) then
        logWriter.WriteLine(msg);

    if(service <> nil) then
        service.LogMessage(msg, EVENTLOG_INFORMATION_TYPE);
end;

procedure Tlog.force(str: string);
begin
    rawLog('', str, TlogLevel.logLevelNone);
end;

procedure Tlog.rawLog(name: string; str: string; level: TlogLevel);
begin
    var msg: string;
    if(logLevel < level) then exit;

    msg := Format(logLeaderFmt, [FormatDateTime(datetimefmt, Now()), name, str]);

    if(logToFile) then
        logWriter.WriteLine(msg);

    if(service <> nil) then
    begin
        case level of
            TlogLevel.logLevelError:    service.LogMessage(msg, EVENTLOG_ERROR_TYPE);
            TlogLevel.logLevelWarning:  service.LogMessage(msg, EVENTLOG_WARNING_TYPE);
            else                        service.LogMessage(msg, EVENTLOG_INFORMATION_TYPE);
        end;
    end;
end;

end.
