function getWCStest

GeoServ = 'https://www.sciencebase.gov/catalogMaps/mapping/ows/50e72cf8e4b00c3282549a83';

feature_collection = 'sb:managedLakes_donut';
attribute = 'WBDY_WBIC'; % attribute in the shapefile that is defined


URI = 'dods://cida-eros-thredds1.er.usgs.gov:8081/qa/thredds/dodsC/temp/Simard_Pinto_3DGlobalVeg_JGR.tif';
GDP = mGDP();       % instantiate the mGDP object

% - set fields or modify fields from the mGDP defaults -
GDP = GDP.setGeoserver(GeoServ);

GDP = GDP.setFeature('FEATURE_COLLECTION',feature_collection,...
    'ATTRIBUTE',attribute,'GML','NULL');

GDP = GDP.setDatasetURI(URI);

GDP = GDP.setPostInputs('TIME_END','NULL','TIME_START','NULL','DATASET_ID',...
    'I0B0');

GDP = GDP.executePost;
disp(GDP.processID)

end

