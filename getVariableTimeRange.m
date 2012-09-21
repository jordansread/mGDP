function [ timeRange] = getVariableTimeRange(datasetURI,varID)

stringSeek  = 'time';
utility = 'timeList';

[ ~, ~, ~, ~, processes] = getParamsGDP;

processURL = processes.(utility);



[ requestXML ] = getUtilityRequestXML( datasetURI, utility,varID);
[ responseXML ] = executePost(requestXML,processURL);

timeRange    = parseXMLforElements(responseXML,stringSeek);