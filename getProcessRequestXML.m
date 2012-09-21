function [ requestXML, processURL ] = getProcessRequestXML( algorithm, POSTinputs, feature )




IN = fieldnames(POSTinputs);

if ~strcmp(POSTinputs.FEATURE_ATTRIBUTE_NAME,feature.ATTRIBUTE)
    error('FEATURE_ATTRIBUTE_NAME must agree in feature and POSTinputs')
end

[ namespaces, schemas, ~, defaults, ...
    processes, endpoints, algorithms] = getParamsGDP;
processURL = processes.process;


%%
docNode = com.mathworks.xml.XMLUtils.createDocument('wps:Execute');
root = docNode.getDocumentElement;
root.setAttribute('service',    'WPS');
root.setAttribute('version',    defaults.wpsVersion);
root.setAttribute('xmlns:wps',  namespaces.wps);
root.setAttribute('xmlns:ows',  namespaces.ows);
root.setAttribute('xmlns:xlink',namespaces.xlink);
root.setAttribute('xmlns:xsi',  namespaces.xsi);
root.setAttribute('xsi:schemaLocation',[namespaces.wps ...
    ' ' schemas.wps]);

%% subelement to root
identifierEL = docNode.createElement('ows:Identifier'); 
identifierEL.appendChild(docNode.createTextNode( algorithms.(algorithm) ));
root.appendChild(identifierEL);

dataInEL = docNode.createElement('wps:DataInputs'); 
root.appendChild(dataInEL);

for i = 1:length(IN)
    inEL     = docNode.createElement('wps:Input'); 
    dataInEL.appendChild(inEL);
    inIdEL   = docNode.createElement('ows:Identifier'); 
    inIdEL.appendChild(docNode.createTextNode(char(IN{i})));
    inEL.appendChild(inIdEL);

    inDatEL  = docNode.createElement('wps:Data');
    inEL.appendChild(inDatEL);

    litDatEL = docNode.createElement('wps:LiteralData');
    litDatEL.appendChild(docNode.createTextNode(POSTinputs.(IN{i})));
    inDatEL.appendChild(litDatEL);
end

%% complex data
inEL     = docNode.createElement('wps:Input');
dataInEL.appendChild(inEL);
inIdEL   = docNode.createElement('ows:Identifier');
inIdEL.appendChild(docNode.createTextNode('FEATURE_COLLECTION'));
inEL.appendChild(inIdEL);

inDatEL  = docNode.createElement('wps:Reference');
inDatEL.setAttribute('xlink:href',endpoints.wfs);
inEL.appendChild(inDatEL);

bodyEL   = docNode.createElement('wps:Body');
inDatEL.appendChild(bodyEL);

featEL   = docNode.createElement('wfs:GetFeature');
featEL.setAttribute('service',  'WFS');
featEL.setAttribute('version',  defaults.wfsVersion);
featEL.setAttribute('outputFormat','text/xml; subtype=gml/3.1.1');
featEL.setAttribute('xmlns:wfs',namespaces.wfs);
featEL.setAttribute('xmlns:ogc',namespaces.ogc);
featEL.setAttribute('xmlns:gml',namespaces.gml);
featEL.setAttribute('xmlns:xsi',namespaces.xsi);
featEL.setAttribute('xsi:schemaLocation',schemas.xsi);
bodyEL.appendChild(featEL);

queryEL  = docNode.createElement('wfs:Query');
queryEL.setAttribute('typeName',feature.FEATURE_COLLECTION);
featEL.appendChild(queryEL);

propNmEL = docNode.createElement('wfs:PropertyName');
propNmEL.appendChild(docNode.createTextNode('the_geom'));
queryEL.appendChild(propNmEL);

propNmEL = docNode.createElement('wfs:PropertyName');
propNmEL.appendChild(docNode.createTextNode(feature.ATTRIBUTE));
queryEL.appendChild(propNmEL);

if ~isempty(feature.GML)
    filterEL    = docNode.createElement('ogc:Filter');
    queryEL.appendChild(filterEL);
    
    gmlObEL  = docNode.createElement('ogc:GmlObjectId');
    gmlObEL.setAttribute('gml:id',feature.GML)
    filterEL.appendChild(gmlObEL);

    
end


%% build response form

resForm = docNode.createElement('wps:ResponseForm');
root.appendChild(resForm);

resDoc  = docNode.createElement('wps:ResponseDocument');
resDoc.setAttribute('storeExecuteResponse','true');
resDoc.setAttribute('status','true');
resForm.appendChild(resDoc);

resOut  = docNode.createElement('wps:Output');
resOut.setAttribute('asReference','true');
resDoc.appendChild(resOut);

outID   = docNode.createElement('ows:Identifier');
outID.appendChild(docNode.createTextNode('OUTPUT'));
resOut.appendChild(outID);

requestXML = xmlwrite(docNode);

% FAKE XML --
%requestXML = '<wps:Execute service="WPS" version="1.0.0" xmlns:wps="http://www.opengis.net/wps/1.0.0" xmlns:ows="http://www.opengis.net/ows/1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wps/1.0.0 http://schemas.opengis.net/wps/1.0.0/wpsExecute_request.xsd"><ows:Identifier>gov.usgs.cida.gdp.wps.algorithm.FeatureWeightedGridStatisticsAlgorithm</ows:Identifier><wps:DataInputs><wps:Input><ows:Identifier>FEATURE_ATTRIBUTE_NAME</ows:Identifier><wps:Data><wps:LiteralData>STATE</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>DATASET_URI</ows:Identifier><wps:Data><wps:LiteralData>dods://cida.usgs.gov/qa/thredds/dodsC/prism</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>DATASET_ID</ows:Identifier><wps:Data><wps:LiteralData>ppt</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>TIME_START</ows:Identifier><wps:Data><wps:LiteralData>1895-01-01T00:00:00.000Z</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>TIME_END</ows:Identifier><wps:Data><wps:LiteralData>1904-11-01T00:00:00.000Z</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>REQUIRE_FULL_COVERAGE</ows:Identifier><wps:Data><wps:LiteralData>true</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>DELIMITER</ows:Identifier><wps:Data><wps:LiteralData>COMMA</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>STATISTICS</ows:Identifier><wps:Data><wps:LiteralData>MEAN</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>GROUP_BY</ows:Identifier><wps:Data><wps:LiteralData>STATISTIC</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>SUMMARIZE_TIMESTEP</ows:Identifier><wps:Data><wps:LiteralData>false</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>SUMMARIZE_FEATURE_ATTRIBUTE</ows:Identifier><wps:Data><wps:LiteralData>false</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>FEATURE_COLLECTION</ows:Identifier><wps:Reference xlink:href="http://cida-eros-gdp2.er.usgs.gov:8082/geoserver/wfs"><wps:Body><wfs:GetFeature service="WFS" version="1.1.0" outputFormat="text/xml; subtype=gml/3.1.1" xmlns:wfs="http://www.opengis.net/wfs" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wfs ../wfs/1.1.0/WFS.xsd"><wfs:Query typeName="sample:CONUS_States"><wfs:PropertyName>the_geom</wfs:PropertyName><wfs:PropertyName>STATE</wfs:PropertyName><ogc:Filter><ogc:GmlObjectId gml:id="CONUS_States.733"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.872"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.881"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.883"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.884"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.885"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.886"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.887"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.889"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.890"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.892"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.893"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.895"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.896"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.897"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.898"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.899"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.903"></ogc:GmlObjectId><ogc:GmlObjectId gml:id="CONUS_States.906"></ogc:GmlObjectId></ogc:Filter></wfs:Query></wfs:GetFeature></wps:Body></wps:Reference></wps:Input></wps:DataInputs><wps:ResponseForm><wps:ResponseDocument storeExecuteResponse="true" status="true"><wps:Output asReference="true"><ows:Identifier>OUTPUT</ows:Identifier></wps:Output></wps:ResponseDocument></wps:ResponseForm></wps:Execute>';
%requestXML = '<wps:Execute service="WPS" version="1.0.0" xmlns:wps="http://www.opengis.net/wps/1.0.0" xmlns:ows="http://www.opengis.net/ows/1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wps/1.0.0 http://schemas.opengis.net/wps/1.0.0/wpsExecute_request.xsd"><ows:Identifier>gov.usgs.cida.gdp.wps.algorithm.FeatureWeightedGridStatisticsAlgorithm</ows:Identifier><wps:DataInputs><wps:Input><ows:Identifier>FEATURE_ATTRIBUTE_NAME</ows:Identifier><wps:Data><wps:LiteralData>STATE</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>DATASET_URI</ows:Identifier><wps:Data><wps:LiteralData>dods://cida.usgs.gov/qa/thredds/dodsC/prism</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>DATASET_ID</ows:Identifier><wps:Data><wps:LiteralData>ppt</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>TIME_START</ows:Identifier><wps:Data><wps:LiteralData>1895-01-01T00:00:00.000Z</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>TIME_END</ows:Identifier><wps:Data><wps:LiteralData>1904-11-01T00:00:00.000Z</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>REQUIRE_FULL_COVERAGE</ows:Identifier><wps:Data><wps:LiteralData>true</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>DELIMITER</ows:Identifier><wps:Data><wps:LiteralData>COMMA</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>STATISTICS</ows:Identifier><wps:Data><wps:LiteralData>MEAN</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>GROUP_BY</ows:Identifier><wps:Data><wps:LiteralData>STATISTIC</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>SUMMARIZE_TIMESTEP</ows:Identifier><wps:Data><wps:LiteralData>false</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>SUMMARIZE_FEATURE_ATTRIBUTE</ows:Identifier><wps:Data><wps:LiteralData>false</wps:LiteralData></wps:Data></wps:Input><wps:Input><ows:Identifier>FEATURE_COLLECTION</ows:Identifier><wps:Reference xlink:href="http://cida-eros-gdp2.er.usgs.gov:8082/geoserver/wfs"><wps:Body><wfs:GetFeature service="WFS" version="1.1.0" outputFormat="text/xml; subtype=gml/3.1.1" xmlns:wfs="http://www.opengis.net/wfs" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wfs ../wfs/1.1.0/WFS.xsd"><wfs:Query typeName="sample:CONUS_States"><wfs:PropertyName>the_geom</wfs:PropertyName><wfs:PropertyName>STATE</wfs:PropertyName><ogc:Filter><ogc:GmlObjectId gml:id="CONUS_States.906"></ogc:GmlObjectId></ogc:Filter></wfs:Query></wfs:GetFeature></wps:Body></wps:Reference></wps:Input></wps:DataInputs><wps:ResponseForm><wps:ResponseDocument storeExecuteResponse="true" status="true"><wps:Output asReference="true"><ows:Identifier>OUTPUT</ows:Identifier></wps:Output></wps:ResponseDocument></wps:ResponseForm></wps:Execute>';

end

