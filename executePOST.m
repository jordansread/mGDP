function [responseXML] = executePOST(requestXML,processURL)


import java.io.*
import java.net.*
import com.mathworks.mlwidgets.io.InterruptibleStreamCopier


url      = URL(processURL);
httpConn = url.openConnection;

httpConn.setRequestProperty('Content-Type','text/xml; charset=utf-8')
httpConn.setRequestMethod('POST')
httpConn.setDoOutput(true)
httpConn.setDoInput(true)

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



end

