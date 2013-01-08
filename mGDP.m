classdef mGDP
    
    properties (Hidden)
        
        processID = [];
        
        WPS_DEFAULT_VERSION = '1.0.0';
        WFS_DEFAULT_VERSION = '1.1.0';
        WPS_DEFAULT_NAMESPACE='http://www.opengis.net/wps/1.0.0';
        OWS_DEFAULT_NAMESPACE='http://www.opengis.net/ows/1.1';
        % *schema definitions
        WPS_SCHEMA_LOCATION = ['http://schemas.opengis.net/'...
            'wps/1.0.0/wpsExecute_request.xsd'];
        XSI_SCHEMA_LOCATION = 'http://www.opengis.net/wfs ../wfs/1.1.0/WFS.xsd';
        GML_SCHEMA_LOCATION = ['http://schemas.opengis.net/gml/3.1.1/'...
            'base/feature.xsd'];
        DRAW_SCHEMA_LOCATION = ['http://cida.usgs.gov/qa/climate/'...
            'derivative/xsd/draw.xsd'];
        % *namesspace definitions
        WFS_NAMESPACE   = 'http://www.opengis.net/wfs';
        OGC_NAMESPACE   = 'http://www.opengis.net/ogc';
        GML_NAMESPACE   = 'http://www.opengis.net/gml';
        DRAW_NAMESPACE  = 'gov.usgs.cida.gdp.draw';
        SMPL_NAMESPACE  = 'gov.usgs.cida.gdp.sample';
        UPLD_NAMESPACE  = 'gov.usgs.cida.gdp.upload';
        CSW_NAMESPACE   = 'http://www.opengis.net/cat/csw/2.0.2';
        XLINK_NAMESPACE = 'http://www.w3.org/1999/xlink';
        XSI_NAMESPACE   = 'http://www.w3.org/2001/XMLSchema-instance';
        
        UTILITY_URL = 'http://cida.usgs.gov/gdp/utility/WebProcessingService';
        UPLOAD_URL  = 'http://cida.usgs.gov/gdp/geoserver/';
        
        algorithms = struct(...
            'FWGS',['gov.usgs.cida.gdp.wps.algorithm.'...
            'FeatureWeightedGridStatisticsAlgorithm'],...
            'FCOD',['gov.usgs.cida.gdp.wps.algorithm.'...
            'FeatureCoverageOPeNDAPIntersectionAlgorithm'],...
            'FCI',['gov.usgs.cida.gdp.wps.algorithm.'...
            'FeatureCoverageIntersectionAlgorithm'],...
            'FCGC',['gov.usgs.cida.gdp.wps.algorithm.'...
            'FeatureCategoricalGridCoverageAlgorithm']);
        
        % *list of utilities available to this module
        upload      = ['gov.usgs.cida.gdp.wps.algorithm.'...
            'filemanagement.ReceiveFiles'];
        dataList    = ['gov.usgs.cida.gdp.wps.algorithm.'...
            'discovery.ListOpendapGrids'];
        timeList    = ['gov.usgs.cida.gdp.wps.algorithm.'...
            'discovery.GetGridTimeRange'];
        emailK      = ['gov.usgs.cida.gdp.wps.algorithm.'...
            'communication.EmailWhenFinishedAlgorithm'];
        
        default_WFS = 'http://cida.usgs.gov/gdp/geoserver/wfs';
        default_WPS = 'http://cida.usgs.gov/gdp/process/WebProcessingService';
        default_URI = 'dods://cida.usgs.gov/qa/thredds/dodsC/prism';
        default_alg = 'FWGS';
        default_post= [];
        default_feat= struct(...
            'FEATURE_COLLECTION',   'sample:CONUS_States',...
            'ATTRIBUTE',            'STATE',...
            'GML',                  'CONUS_States.906');
    end
    
    % can only be set by methods
    properties (SetAccess = private)
        
        % *global urls for GDP and services
        WFS_URL     = [];
        PROCESS_URL = [];
        datasetURI  = [];
        algorithm   = [];
        PostInputs  = [];
        feature     = [];

    end
    
    %% 
    methods
        function GDP = mGDP()
            
            GDP.WFS_URL     = GDP.default_WFS;
            GDP.PROCESS_URL = GDP.default_WPS;
            GDP.datasetURI  = GDP.default_URI;
            GDP.PostInputs  = GDP.default_post;
            GDP.PostInputs.FEATURE_ATTRIBUTE_NAME = ...
                GDP.default_feat.ATTRIBUTE;
            GDP.feature     = GDP.default_feat;
            GDP = GDP.setAlgorithm(GDP.default_alg);
            % testing defaults
            GDP = GDP.setPostInputs('DATASET_ID','ppt',...
                'TIME_START','1895-01-01T00:00:00.000Z',...
                'TIME_END',  '1905-01-01T00:00:00.000Z');
            
        end
        function [ shapefiles ] = getShapefiles(GDP)
            
            seekString = 'Name';      
            
            processURL = [GDP.WFS_URL...
                '?service=WFS&version=' GDP.WPS_DEFAULT_VERSION '&request=GetCapabilities'];
            
            [responseXML] = urlread(processURL);
            shapefiles = parseXMLforElements(responseXML, seekString);
            
        end
        function [ attributes ] = getAttributes(GDP,shapefile)
            
            seekString = 'name';

            processURL = [GDP.WFS_URL...
                '?service=WFS&version=' GDP.WPS_DEFAULT_VERSION '&request=DescribeFeatureType'...
                '&typename=' shapefile];
            
            [responseXML] = urlread(processURL);
            
            attributes = parseXMLforAttributes(responseXML, seekString);
            attributes = attributes(2:end);     % first one is the name of the shapefile
            
        end
        function [ values ] = getValues(GDP,shapefile,attribute)

            processURL = [GDP.WFS_URL...
                '?service=WFS&version=' GDP.WPS_DEFAULT_VERSION '&request=GetFeature'...
                '&info_format=text%2Fxml&typename=' shapefile...
                '&propertyname=' attribute];
            
            [responseXML] = urlread(processURL);
            seekString = 'gml:id';
            if isempty(strfind(responseXML,seekString))
                seekString = 'fid';
            end
            values = parseXMLforAttributes(responseXML, seekString);
            
        end
        function [ fileURL , status ] = checkProcess( GDP, responseXML )
            
            
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
            startIdx = regexp(GDP.processID,'=');
            processNum= [GDP.processID(startIdx+1:end) 'OUTPUT'];    % will only be found when process is complete?
            fileRoot = GDP.processID(1:startIdx);
            
            status = false;
            
            responseXML = urlread(GDP.processID);
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
        end
        function GDP = executePost(GDP)
            
            
            import java.io.*
            import java.net.*
            import com.mathworks.mlwidgets.io.InterruptibleStreamCopier
            
            
            url      = URL(GDP.PROCESS_URL);
            httpConn = url.openConnection;
            
            httpConn.setRequestProperty('Content-Type','text/xml; charset=utf-8')
            httpConn.setRequestMethod('POST')
            httpConn.setDoOutput(true)
            httpConn.setDoInput(true)
            
            requestXML = postInputsToXML(GDP);
            toSend = java.lang.String(requestXML);
            b = toSend.getBytes('UTF8');
            
            outputStream = httpConn.getOutputStream;
            outputStream.write(b);
            outputStream.close;
            
            inputStream = httpConn.getInputStream;
            byteArrayOutputStream = java.io.ByteArrayOutputStream;
            isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
            isc.copyStream(inputStream,byteArrayOutputStream);
            inputStream.close;
            byteArrayOutputStream.close;
            
            responseXML = char(byteArrayOutputStream.toString('UTF-8'));
            prssID = getProcessID( responseXML );
            GDP = setProcessID(GDP,prssID);
        end




    end
    %% -
    methods
        
        function GDP = setGeoserver(GDP,wfs)
            GDP.WFS_URL = wfs;
        end
        
        function GDP = setDatasetURI(GDP,URI)
            GDP.datasetURI  = URI;
        end
        function GDP = setFeature( GDP, varargin )
            
            
            % provide key value pairs to change POSTinputs structure
            
            numArgs = length(varargin);
            
            if ne(rem(numArgs,2),0)
                error('arguments must be made in pairs')
            end
            
            for i = 1:2:numArgs
                fieldName = varargin{i};
                GDP.feature.(fieldName) = varargin{i+1};
            end
            
        end
        function GDP = setPostInputs( GDP, varargin )
            
            
            % provide key value pairs to change POSTinputs structure
            
            numArgs = length(varargin);
            
            if ne(rem(numArgs,2),0)
                error('arguments must be made in pairs')
            end
            
            for i = 1:2:numArgs
                fieldName = varargin{i};
                GDP.PostInputs.(fieldName) = varargin{i+1};
            end
            
        end
        function GDP = setAlgorithm( GDP, algorithm )
            
            
            % provide key value pairs to change POSTinputs structure
            GDP.algorithm = algorithm;
            GDP = initPostInputs (GDP);
            
        end

        
    end
    %% --- private methods
    methods (Access = private)
        function GDP = setProcessID(GDP,processID)
            GDP.processID = processID;
        end
        function GDP = initPostInputs(GDP)
            
            regE = '#';
            % -- variables --
            GDP.PostInputs = struct(...
                'FEATURE_ATTRIBUTE_NAME', [],...
                'DATASET_URI',  GDP.datasetURI,...
                'DATASET_ID',   [],...      % this is the variable name
                'TIME_START',   [],...
                'TIME_END',     [],...
                'REQUIRE_FULL_COVERAGE','true',...
                'DELIMITER',    'COMMA',...
                'STATISTICS',   'MEAN',...
                'GROUP_BY',     'STATISTIC',...
                'SUMMARIZE_TIMESTEP', 'false',...
                'SUMMARIZE_FEATURE_ATTRIBUTE', 'false');
            
            if isfield(GDP.feature,'ATTRIBUTE')
                GDP.PostInputs.FEATURE_ATTRIBUTE_NAME = ...
                    GDP.feature.ATTRIBUTE;
            end

            removeFields = struct(...
                'FWGS',     {''},...
                'FCOD',     {['FEATURE_ATTRIBUTE_NAME' regE...
                'SUMMARIZE_FEATURE_ATTRIBUTE' regE...
                'SUMMARIZE_TIMESTEP' regE...
                'GROUP_BY' regE...
                'STATISTICS' regE...
                'DELIMITER' regE]},...
                'FCI',      {['FEATURE_ATTRIBUTE_NAME' regE...
                'TIME_START' regE...
                'TIME_END' regE...
                'SUMMARIZE_FEATURE_ATTRIBUTE' regE...
                'SUMMARIZE_TIMESTEP' regE...
                'GROUP_BY' regE...
                'STATISTICS' regE...
                'DELIMITER' regE]},...
                'FCGC',     {['SUMMARIZE_FEATURE_ATTRIBUTE' regE...
                'TIME_START' regE...
                'TIME_END' regE...
                'SUMMARIZE_TIMESTEP' regE...
                'GROUP_BY' regE...
                'STATISTICS' regE]});
            
            
            
            rmvFN = removeFields.(GDP.algorithm);
            
            splitIdx = regexp(rmvFN,regE);
            
            for i = 1:length(splitIdx)
                if eq(i,1)
                    GDP.PostInputs = rmfield(GDP.PostInputs,rmvFN(1:splitIdx(i)-1));
                else
                    GDP.PostInputs = rmfield(GDP.PostInputs,rmvFN(splitIdx(i-1)+1:splitIdx(i)-1));
                end
                
            end
            
        end
        function elements = parseXMLforElements(responseXML, seekString)
            seekStart = ['<'  seekString '>'];
            seekEnd   = ['</' seekString '>'];
            
            
            [~,matchend] = regexp(responseXML,seekStart);
            [matchstart] = regexp(responseXML,seekEnd);
            
            numShp = length(matchend);
            
            if ne(numShp,length(matchstart))
                error(['XML not properly closed with ' seekStart ' and ' seekEnd])
            end
            
            elements = cell(numShp,1);
            
            for i = 1:numShp
                elements{i} = responseXML(matchend(i)+1:matchstart(i)-1);
            end

        end
        function attributes = parseXMLforAttributes(responseXML, seekString)
            
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
            
            attributes = cell(numShp,1);
            
            for i = 1:numShp
                attributes{i} = responseXML(matchend(i)+1:realMS(i)-1);
            end
        end
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
        function requestXML = postInputsToXML(GDP)
            
            IN = fieldnames(GDP.PostInputs);
            
            if ~strcmp(GDP.PostInputs.FEATURE_ATTRIBUTE_NAME,GDP.feature.ATTRIBUTE)
                error('FEATURE_ATTRIBUTE_NAME must agree in feature and PostInputs')
            end

            %%
            docNode = com.mathworks.xml.XMLUtils.createDocument('wps:Execute');
            root = docNode.getDocumentElement;
            root.setAttribute('service',    'WPS');
            root.setAttribute('version',    GDP.WPS_DEFAULT_VERSION);
            root.setAttribute('xmlns:wps',  GDP.WPS_DEFAULT_NAMESPACE);
            root.setAttribute('xmlns:ows',  GDP.OWS_DEFAULT_NAMESPACE);
            root.setAttribute('xmlns:xlink',GDP.XLINK_NAMESPACE);
            root.setAttribute('xmlns:xsi',  GDP.XSI_NAMESPACE);
            root.setAttribute('xsi:schemaLocation',[GDP.WPS_DEFAULT_NAMESPACE ...
                ' ' GDP.WPS_SCHEMA_LOCATION]);
            
            %% subelement to root
            identifierEL = docNode.createElement('ows:Identifier');
            identifierEL.appendChild(docNode.createTextNode( GDP.algorithms.(GDP.algorithm) )); % tricky...
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
                litDatEL.appendChild(docNode.createTextNode(GDP.PostInputs.(IN{i})));
                inDatEL.appendChild(litDatEL);
            end
            
            %% complex data
            inEL     = docNode.createElement('wps:Input');
            dataInEL.appendChild(inEL);
            inIdEL   = docNode.createElement('ows:Identifier');
            inIdEL.appendChild(docNode.createTextNode('FEATURE_COLLECTION'));
            inEL.appendChild(inIdEL);
            
            inDatEL  = docNode.createElement('wps:Reference');
            inDatEL.setAttribute('xlink:href',GDP.WFS_URL);
            inEL.appendChild(inDatEL);
            
            bodyEL   = docNode.createElement('wps:Body');
            inDatEL.appendChild(bodyEL);
            
            featEL   = docNode.createElement('wfs:GetFeature');
            featEL.setAttribute('service',  'WFS');
            featEL.setAttribute('version',  GDP.WFS_DEFAULT_VERSION);
            featEL.setAttribute('outputFormat','text/xml; subtype=gml/3.1.1');
            featEL.setAttribute('xmlns:wfs',GDP.WFS_NAMESPACE);
            featEL.setAttribute('xmlns:ogc',GDP.OGC_NAMESPACE);
            featEL.setAttribute('xmlns:gml',GDP.GML_NAMESPACE);
            featEL.setAttribute('xmlns:xsi',GDP.XSI_NAMESPACE);
            featEL.setAttribute('xsi:schemaLocation',GDP.XSI_SCHEMA_LOCATION);
            bodyEL.appendChild(featEL);
            
            queryEL  = docNode.createElement('wfs:Query');
            queryEL.setAttribute('typeName',GDP.feature.FEATURE_COLLECTION);
            featEL.appendChild(queryEL);
            
            propNmEL = docNode.createElement('wfs:PropertyName');
            propNmEL.appendChild(docNode.createTextNode('the_geom'));
            queryEL.appendChild(propNmEL);
            
            propNmEL = docNode.createElement('wfs:PropertyName');
            propNmEL.appendChild(docNode.createTextNode(GDP.feature.ATTRIBUTE));
            queryEL.appendChild(propNmEL);
            
            if ~isempty(GDP.feature.GML)
                filterEL    = docNode.createElement('ogc:Filter');
                queryEL.appendChild(filterEL);
                
                gmlObEL  = docNode.createElement('ogc:GmlObjectId');
                gmlObEL.setAttribute('gml:id',GDP.feature.GML)
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
        end
        
    end
    
    
    
end

