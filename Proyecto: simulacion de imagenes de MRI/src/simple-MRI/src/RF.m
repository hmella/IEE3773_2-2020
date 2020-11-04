classdef RF
    properties
        angle       % rad
        phase       % rad
        dur         % msec
        ref         % object order in the sequence
        ref_obj     % gradient or rf object
        ref_delay   % delay time from reference object (msec)
        time  = []; 
    end

    methods
        function obj = RF(varargin)

            % Default arguments
            defapi = struct('angle',pi/2,'phase',0,'dur',1,'ref',[],...
              'ref_obj',[],'ref_delay',0,'time',[]);

            % Parse inputs
            api = parseinputs(defapi,[],varargin{:});
            objects = fieldnames(api);
            for i=1:numel(objects)
                obj.(objects{i}) = api.(objects{i});
            end

            % Check reference
            if strcmp(obj.ref_obj,'ref')
                obj.ref  = 1;    % update reference index
                obj.time = 0;    % update time
            elseif ~isempty(obj.ref_obj)
                obj.ref  = obj.ref_obj.ref + 1;                                % update reference index
                obj.time = obj.ref_obj.time + obj.ref_obj.dur + obj.ref_delay; % update time
            end

        end
    end    

end
