function [ shapefiles ] = getShapefiles

seekString = 'Name';

[ ~, ~, ~, defaults, ~, endpoints] = getParamsGDP;


processURL = [endpoints.wfs...
    '?service=WFS&version=' defaults.wfsVersion '&request=GetCapabilities'];


[responseXML] = urlread(processURL);

shapefiles = parseXMLforElements(responseXML, seekString);

end

