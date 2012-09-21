function [ values ] = getValues(shapefile,attribute)

seekString = 'gml:id';%['sample:' attribute];



[ ~, ~, ~, defaults, ~, endpoints] = getParamsGDP;

processURL = [endpoints.wfs...
    '?service=WFS&version=' defaults.wfsVersion '&request=GetFeature'...
    '&info_format=text%2Fxml&typename=' shapefile...
    '&propertyname=' attribute];

[responseXML] = urlread(processURL);

values = parseXMLforAttributes(responseXML, seekString);


end

