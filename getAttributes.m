function [ attributes ] = getAttributes(shapefile)

seekString = 'name';



[ ~, ~, ~, defaults, ~, endpoints] = getParamsGDP;

processURL = [endpoints.wfs...
    '?service=WFS&version=' defaults.wfsVersion '&request=DescribeFeatureType'...
    '&typename=' shapefile];

[responseXML] = urlread(processURL);

attributes = parseXMLforAttributes(responseXML, seekString);
attributes = attributes(2:end);     % first one is the name of the shapefile
end

