classdef gen
    % GENERIC INSTRUMENT class
    % by Avico
    properties
        conn
        idn@char
    end
    
    methods
        %% Constructor
        function self = gen(vendor, rsrcname, idn, varargin)
            inputNames = {'vendor', 'rsrcname', 'idn'};
            if nargin == 0
                %% create an "empty" instrument object for independent connection control (e.g. M8190A)
                self.idn    = 'unknown';
                self.conn   = NaN;
            else
                %% Connect instrument
                % Verify inputs
                for i = 1:length(inputNames)
                    if ~eval(['ischar(' inputNames{i} ')'])
                        error('GENERIC INSTRUMENT: input ''%s'' is not char type', inputNames{i})
                    end
                end
                % Find already open connection for this resource
                f = instrfind('Status', 'Open', 'RsrcName', rsrcname, 'Tag', '');
                if ~isempty(f)
                    self.conn = f(1); % retrieve open connection
                else
                    self.conn = visa(vendor, rsrcname); % connect via visa
                end
                self.idn    = idn;
                len = nargin-3;
                if len > 0 % any additional settings for connection struct (TimeOut, InputBufferSize...)
                    if mod(len,2) > 0,                      error('%s: check input field name and value pairings', self.idn); end
                    fieldNames  = varargin(1:2:end);
                    vals      = varargin(2:2:end);
                    if ~all(cellfun(@ischar,fieldNames)),   error('%s: some field names are not char type', self.idn); end
                    for i = 1:len/2
                        self.conn.(fieldNames{i}) = vals{i};
                    end
                end
                self.open(); % open connection
            end
        end
        function open(self)
            %% OPEN connection if not open already
            if strcmp(self.conn.Status, 'closed')
                try
                    fopen(self.conn);
                catch
                    errordlg({sprintf('Could not open connection to %s.', self.idn), ...
                              'Please verify that you specified the correct address' ...
                              }, 'Error');
                end
            end
        end
        function close(self, suppressWarn)
            %% CLOSE connection if opened
            if strcmp(self.conn.Status, 'open')
                fclose(self.conn);
            else
                %% Warn that the connection is already closed unless supressed
                ex = exist('suppressWarn','var');
                if (~ex || (ex && ~suppressWarn))
                    warning('%s is already closed', self.idn)
                end
            end
        end
        function s = isopen(self, suppressErr)
            %% Check if connection is opened
            s = strcmp(self.conn.Status, 'open');
            ex = exist('suppressErr','var');
            if ~s && (~ex || (ex && ~suppressErr))
                errordlg([self.idn ': connection is closed, no command was sent']);
            end
        end
        %% Read, write and query: shorthand
        function fread(self,varargin)
            if self.isopen()
                fread(self.conn, varargin{:});
            end
        end
        function iprintf(self,varargin)
            if self.isopen()
                fprintf(self.conn, varargin{:});
            end
        end
        function answer = iscanf(self,varargin)
            if self.isopen()
                answer = fscanf(self.conn, varargin{:});
                self.chckLstCmd();
            end
        end
        function answer = query(self,varargin)
            if self.isopen()
                answer = query(self.conn, varargin{:});
            end
        end
        function answer = binblockread(self,varargin)
            if self.isopen()
                answer = binblockread(self.conn, varargin{:});
            end
        end

        function chckLstCmd(self)
            %% Check last command for errors
            result = query(self.conn, ':syst:err?');
            if (isempty(result))
                errordlg([self.idn ': did not respond to :SYST:ERR query. Check the instrument.'], 'Error');
                error(':syst:err query failed');
            end
            if ~(strcmp(strtrim(result), '0') || ~isempty(regexpi(result, 'No error')))
                fprintf(self.conn, '*CLS'); % clear error quo
%                 errordlg({self.idn ': returns an error. Error Message:' result});
                error('%s: returns an error. Error Message: %s', self.idn, result);
            end
        end
    end
    
end

