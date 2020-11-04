classdef GR
    properties
        dir         % encoding direction
        amp         % mT/m
        dur         % milliseconds
        ref         % object order in the sequence    
        ref_obj     % gradient or rf object
        ref_delay   % delay time from reference object
        time
        crusher
    end

    methods
        function obj = GR(varargin)

            % Default arguments
            defapi = struct('dir',1,'amp',50,'dur',5,'ref',[],...
              'ref_obj',[],'ref_delay',0,'time',[],'crusher',false);

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

