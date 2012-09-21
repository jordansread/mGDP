function [ outputStrings ] = parseXMLforAttributes(responseXML, seekString)

seekStart = [seekString '="'];
seekEnd   = '"';


[~,matchend] = regexp(responseXML,seekStart);
[matchstart] = regexp(responseXML,seekEnd);

numShp = length(matchend);

% find matchend pairs
realMS = matchend;
for i = 1:numShp
    realMS(i) = matchstart(find(matchend(i)<matchstart,1, 'first'));
end
outputStrings = cell(numShp,1);

for i = 1:numShp
    outputStrings{i} = responseXML(matchend(i)+1:realMS(i)-1);
end

end