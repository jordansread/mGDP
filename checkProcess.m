function [ fileURL , status ] = checkProcess( processID, responseXML )


txtStart = [];
fileURL  = ' ';
matSec   = 86400;   % seconds in a day
if eq(nargin,2)
    % parse XML and find creation time
    stringSeek = 'creationTime=';
    stringRmv  = '"';
    
    
    [startIdx] = regexp(responseXML,stringSeek);
    conStr     = responseXML(startIdx:end);
    
    % now bookend with stringRmv
    
    bookend    = regexp(conStr, stringRmv);
    startTime  = conStr(bookend(1)+1:bookend(2)-11);
    startTime  = datenum(startTime,'yyyy-mm-ddTHH:MM:SS');
    txtStart = [txtStart 'after ' num2str((now-startTime)*matSec) ' seconds, '];

end

stringRmv  = '"';

% find unique process ID #
startIdx = regexp(processID,'=');
processNum= [processID(startIdx+1:end) 'OUTPUT'];    % will only be found when process is complete?
fileRoot = processID(1:startIdx);

status = false;

responseXML = urlread(processID);
% check if responseXML contains download link
[startIdx] = regexp(responseXML,processNum);
if ~isempty(startIdx)
    status = true;
    conStr = responseXML(startIdx:end);
    [endIdx] = regexp(conStr,stringRmv);
    fileNum  = conStr(1:endIdx(1)-1);
    fileURL  = [fileRoot fileNum];
    disp([txtStart 'process complete'])
else
    disp([txtStart 'process incomplete'])
    
    
end

