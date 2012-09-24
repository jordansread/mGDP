function [ POSTinputs ] = setPostInputs( POSTinputs, varargin )


% provide key value pairs to change POSTinputs structure

numArgs = length(varargin);

if ne(rem(numArgs,2),0)
    error('arguments must be made in pairs')
end

for i = 1:2:numArgs
    fieldName = varargin{i};
    POSTinputs.(fieldName) = varargin{i+1};
end

end

