function [ varIDs, varLongNames] = getVariableIDs(datasetURI)

IDseek  = 'name';
LNseek  = 'description';
utility = 'dataList';
varID   = [];

[ ~, ~, ~, ~, processes] = getParamsGDP;

processURL = processes.(utility);



[ requestXML ] = getUtilityRequestXML( datasetURI, utility,varID);
[ responseXML ] = executePOST(requestXML,processURL);

varIDs       = parseXMLforElements(responseXML,IDseek);
varLongNames = parseXMLforElements(responseXML,LNseek);

end

