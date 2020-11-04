classdef Preparation
    properties
        objects
        timing
        rf_pulses
        gradients
        RF1
        RF2
        RF3
        RF4
        RF5
        RF6
        GR1
        GR2
        GR3
        GR4
        GR5
        GR6
    end

    methods
        function obj = Preparation(varargin)

            % Default arguments
            rf_tmp = RF(struct('angle',90,'phase',0,'ref',[],'ref_obj',[],'time',0));
            defapi = struct(...
                        'RF1',rf_tmp,...
                        'RF2',[],...
                        'RF3',[],...
                        'RF4',[],...
                        'RF5',[],...
                        'RF6',[],...
                        'GR1',[],...
                        'GR2',[],...
                        'GR3',[],...
                        'GR4',[],...
                        'GR5',[],...
                        'GR6',[]);

            % Parse inputs
            api = parseinputs(defapi,[],varargin{:});
            objects = fieldnames(api);
            for i=1:numel(objects)
                obj.(objects{i}) = api.(objects{i});
            end

            % Check number of valid objects
            valid_obj = {};
            nobj = 0;
            for i=1:numel(objects)
                if ~isempty(obj.(objects{i}))
                    nobj = nobj + 1;
                    valid_obj{nobj} = obj.(objects{i});
                end
            end
            
            % Get objects ordered
            obj.objects = cell([1 nobj]);
            obj.rf_pulses = cell([1 nobj]);
            obj.gradients = cell([1 nobj]);
            for i=1:nobj
                obj.objects{valid_obj{i}.ref} = valid_obj{i};
                if strcmp(class(valid_obj{i}),'RF')
                    obj.rf_pulses{valid_obj{i}.ref} = valid_obj{i};
                elseif strcmp(class(valid_obj{i}),'GR')
                    obj.gradients{valid_obj{i}.ref} = valid_obj{i};
                end
            end

            % Create timing object based on RF and GR durations
            times = [];
            steps = []; 
            for i=1:nobj
                times(i) = obj.objects{i}.time + obj.objects{i}.dur;
                steps(i) = obj.objects{i}.dur;
            end
            obj.timing = struct('times',times,'dur',steps);

        end
    end

end