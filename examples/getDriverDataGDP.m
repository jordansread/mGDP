function getDriverDataGDP

clc
clear all
%% -- variables --

timerPeriod = 42;   % seconds between checking
retries = 5;        % times to try again after failed process

GeoServ = 'https://www.sciencebase.gov/catalogMaps/mapping/ows/5064a227e4b0050306263069';

varURI= 'dods://www.esrl.noaa.gov/psd/thredds/dodsC/Datasets/NARR/monolevel/dswrf.YYYY.nc';
fileN = 'SW_NARR';
varN  = 'dswrf';
year  = 1998;
YYYY  = num2str(year);

feature_collection = 'sb:mendota';
attribute = 'ComID'; % for WBIC codes...

writeDir= './Driver data/';

%% set processing


GDP = mGDP();

GDP = GDP.setGeoserver(GeoServ);
GDP = GDP.setFeature('FEATURE_COLLECTION',feature_collection,...
    'ATTRIBUTE',attribute,'GML','NULL');

URI = regexprep(varURI,'YYYY',YYYY);
disp(URI)
GDP = GDP.setPostInputs('DATASET_ID',varN,...
    'TIME_START',[YYYY '-01-01T00:00:00.000Z'],...
    'TIME_END',  [YYYY '-12-31T00:00:00.000Z']);
GDP = GDP.setDatasetURI(URI);
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


