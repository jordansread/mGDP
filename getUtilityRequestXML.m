function [ requestXML ] = getUtilityRequestXML( datasetURI, utility, dataType )


if lt(nargin,3)
    dataType = [];
end

[ namespaces, schemas, utilities, defaults ] = getParamsGDP;

dataID = struct(...
    'dataList','allow-cached-response',...
    'timeList','grid',...
    'default','allow-cached-response');
dataLit = struct(...
    'dataList','undefined',...
    'timeList',dataType,...
    'default','undefined');


%%
docNode = com.mathworks.xml.XMLUtils.createDocument('wps:Execute');
root = docNode.getDocumentElement;
root.setAttribute('service',    'WPS');
root.setAttribute('version',    defaults.wpsVersion);
root.setAttribute('xmlns:wps',  namespaces.wps);
root.setAttribute('xmlns:ows',  namespaces.ows);
root.setAttribute('xmlns:wfs',  namespaces.wfs);
root.setAttribute('xmlns:xlink',namespaces.xlink);
root.setAttribute('xmlns:xsi',  namespaces.xsi);
root.setAttribute('xsi:schemaLocation',[namespaces.wps ...
    ' ' schemas.wps]);

% subelement to root
identifierEL = docNode.createElement('ows:Identifier'); 
identifierEL.appendChild(docNode.createTextNode( utilities.(utility) ));
root.appendChild(identifierEL);

dataInEL = docNode.createElement('wps:DataInputs'); 
root.appendChild(dataInEL);

inEL     = docNode.createElement('wps:Input'); 
dataInEL.appendChild(inEL);

inIdEL   = docNode.createElement('ows:Identifier'); 
inIdEL.appendChild(docNode.createTextNode('catalog-url'));
inEL.appendChild(inIdEL);

inDatEL  = docNode.createElement('wps:Data');
inEL.appendChild(inDatEL);

litDatEL = docNode.createElement('wps:LiteralData');
litDatEL.appendChild(docNode.createTextNode(datasetURI));
inDatEL.appendChild(litDatEL);

inEL     = docNode.createElement('wps:Input'); 
dataInEL.appendChild(inEL);

inIdEL   = docNode.createElement('ows:Identifier'); 
inIdEL.appendChild(docNode.createTextNode(dataID.(utility)));
inEL.appendChild(inIdEL);

inDatEL  = docNode.createElement('wps:Data');
inEL.appendChild(inDatEL);

litDatEL = docNode.createElement('wps:LiteralData');
litDatEL.appendChild(docNode.createTextNode(dataLit.(utility)));
inDatEL.appendChild(litDatEL);
if ~isempty(dataType)
    inEL     = docNode.createElement('wps:Input');
    dataInEL.appendChild(inEL);
    
    inIdEL   = docNode.createElement('ows:Identifier');
    inIdEL.appendChild(docNode.createTextNode(dataID.default));
    inEL.appendChild(inIdEL);
    
    inDatEL  = docNode.createElement('wps:Data');
    inEL.appendChild(inDatEL);
    
    litDatEL = docNode.createElement('wps:LiteralData');
    litDatEL.appendChild(docNode.createTextNode(dataLit.default));
    inDatEL.appendChild(litDatEL);
end


% build response form

resForm = docNode.createElement('wps:ResponseForm');
root.appendChild(resForm);

resDoc  = docNode.createElement('wps:ResponseDocument');
resForm.appendChild(resDoc);

resOut  = docNode.createElement('wps:Output');
resDoc.appendChild(resOut);

outID   = docNode.createElement('ows:Identifier');
outID.appendChild(docNode.createTextNode('result'));
resOut.appendChild(outID);

requestXML = xmlwrite(docNode);

                    
end

