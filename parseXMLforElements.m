function [ outputStrings ] = parseXMLforElements(responseXML, seekString)

seekStart = ['<'  seekString '>'];
seekEnd   = ['</' seekString '>'];


[~,matchend] = regexp(responseXML,seekStart);
[matchstart] = regexp(responseXML,seekEnd);

numShp = length(matchend);

if ne(numShp,length(matchstart))
    error(['XML not properly closed with ' seekStart ' and ' seekEnd])
end

outputStrings = cell(numShp,1);

for i = 1:numShp
    outputStrings{i} = responseXML(matchend(i)+1:matchstart(i)-1);
end

end

