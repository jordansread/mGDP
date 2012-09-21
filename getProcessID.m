function [ processID ] = getProcessID( responseXML )

% parse XML and find process ID
stringSeek = 'statusLocation=';

stringRmv  = '"';


[startIdx] = regexp(responseXML,stringSeek);
conStr     = responseXML(startIdx:end);

% now bookend with stringRmv

bookend    = regexp(conStr, stringRmv);
processID  = conStr(bookend(1)+1:bookend(2)-1);


end

