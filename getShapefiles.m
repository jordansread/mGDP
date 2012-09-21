function [ shapefiles ] = getShapefiles

seekString = 'Name';

[ ~, ~, ~, defaults, ~, endpoints] = getParamsGDP;

% sciencebase example: 
endpoints.wfs = 'https://www.sciencebase.gov/catalog/item/get/5058d6ffe4b0eef629c0244f'

processURL = [endpoints.wfs...
    '?service=WFS&version=' defaults.wfsVersion '&request=GetCapabilities'];


[responseXML] = urlread(processURL);

shapefiles = parseXMLforElements(responseXML, seekString);

end

