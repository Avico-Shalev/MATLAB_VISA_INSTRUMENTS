function xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg('Instrument did not respond to :SYST:ERR query. Check the instrument.', 'Error');
        error(':syst:err query failed');
    end
    if (~exist('ignoreError', 'var'))
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'Instrument returns an error on command:' s 'Error Message:' result});
        end
    end
end