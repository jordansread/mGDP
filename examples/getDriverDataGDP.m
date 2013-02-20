function getDriverDataGDP(year)

% getDriverDataGDP is an example for the use of the mGDP object. The
% example takes advantage of the "setGeoserver" method to modify the
% geoserver location from the default (cida.usgs.gov/gdp/geoserver/wfs) to
% a sciencebase host of a shapefile for the lake mendota boundary.

% inputs: year is an integer value required for the file system used by
% NARR organization. 

% usage: getDriverDataGDP(1998); will access and write downwelling sw
% radiation data for lake mendota during the year of 1998. 

% The dataset being used is the downwelling 3 hr shortwave radiation from
% NARR, and the year is defined as a variable.

% getDriverDataGDP sets the appropriate fields in the mGDP object, then
% checks the state of the processing request until it has finished
% (retrying 5 times if it fails) and writes the results to file. 

clc
%% -- variables --

timerPeriod = 42;   % seconds between checking
retries = 5;        % times to try again after failed process

% - new geoserver location defined - 
GeoServ = 'https://www.sciencebase.gov/catalogMaps/mapping/ows/5064a227e4b0050306263069';

% - file ouput specifications - 
fileN = 'SW_NARR';
YYYY  = num2str(year);
writeDir= './Driver data/';

% - feature information related to the shapefile - 
feature_collection = 'sb:mendota';
attribute = 'ComID'; % attribute in the shapefile that is defined

% - URI location and variable name - 
varURI= 'dods://www.esrl.noaa.gov/psd/thredds/dodsC/Datasets/NARR/monolevel/dswrf.YYYY.nc';
varN  = 'dswrf';
URI = regexprep(varURI,'YYYY',YYYY);
disp(URI) % display the processing target dataset

%% set processing
GDP = mGDP();       % instantiate the mGDP object

% - set fields or modify fields from the mGDP defaults -
GDP = GDP.setGeoserver(GeoServ);
GDP = GDP.setFeature('FEATURE_COLLECTION',feature_collection,...
    'ATTRIBUTE',attribute,'GML','NULL');
GDP = GDP.setPostInputs('DATASET_ID',varN,...
    'TIME_START',[YYYY '-01-01T00:00:00.000Z'],...
    'TIME_END',  [YYYY '-12-31T00:00:00.000Z']);
GDP = GDP.setDatasetURI(URI);

% - excecute the defined mGDP post -
GDP = GDP.executePost;

attempt = 1;
retry = false;
done = false;
tic
% now loop and check
mkdir(writeDir,YYYY)
while ~done
    toc
    pause(timerPeriod)
    if retry && ~gt(attempt,retries)
        GDP = GDP.executePost;
        attempt = attempt+1;
        retry = false;
    elseif retry
        done = true;
        disp(['Process failed after ' num2str(attempt)...
            ' attempts']);
    end
    fileNm = [fileN '_' YYYY] ;
    if ~done    % if still not done
        disp(['currently working on ' varN]);
        
        % status can be failed, complete, incomplete, none, or unknown
        [f_Handle,status] = GDP.checkProcess;   % check again
        if strcmp(status,'failed')
            retry = true;       % need to try again with execute
        elseif strcmp(status,'complete')
            done = true;
        elseif strcmp(status,'none')
            error('no process started')
        end
        
        
        if done  % will be first time that done is true
            disp(['***** writing ' YYYY '/' fileNm '.txt *****']);
            urlwrite(f_Handle,[writeDir YYYY '/' fileNm '.txt']);cd ..
        end
    elseif done && retry
        disp(['#$(&@#& '  varN ' process failed #$&(@#$'])
    else
        disp(['*----' varN ' process complete----*'])
    end
    disp(status)
end
clear GDP


