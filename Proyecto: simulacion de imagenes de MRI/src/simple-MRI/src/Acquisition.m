classdef Acquisition
    properties
        objects
        timing
        rf_pulses
        gradients
        TR
        TE
        nb_frames
        prep_delay
        RFdummy
        RF1
        RF2
        RF3
        RF4
        RF5
        GR1
        GR2
        GR3
        GR4
        GR5
    end

    methods
        function obj = Acquisition(varargin)

            % Default arguments
            rf_tmp = RF(struct('angle',15,'phase',0,'ref',[],'ref_obj',[],...
              'ref_delay',0,'time',0));
            defapi = struct(...
                        'TR', 10,...
                        'TE', 5,...
                        'nb_frames', 10,...
                        'prep_delay', 10,...
                        'RFdummy',rf_tmp,...
                        'RF1',rf_tmp,...
                        'RF2',[],...
                        'RF3',[],...
                        'RF4',[],...
                        'RF5',[],...
                        'GR1',[],...
                        'GR2',[],...
                        'GR3',[],...
                        'GR4',[],...
                        'GR5',[]);
            defapi.RFdummy.angle = 0.0;
            defapi.RFdummy.time = defapi.RF1.time-1;
            
            % Parse inputs
            api = parseinputs(defapi,[],varargin{:});
            objects = fieldnames(api);
            for i=1:numel(objects)
                obj.(objects{i}) = api.(objects{i});
            end            
            
            % Check number of valid objects (RF or GR)
            valid_obj = {};
            nobj = 0;
            for i=1:numel(objects)
                is_valid = and(~isempty(obj.(objects{i})), ...
                    or(strcmp(class(obj.(objects{i})),'RF'),...
                     strcmp(class(obj.(objects{i})),'GR')));
                if is_valid
                    nobj = nobj + 1;
                    valid_obj{nobj} = obj.(objects{i});
                end
            end

            % Update timing of base sequence objects
            for i=1:nobj
                valid_obj{i}.time = valid_obj{i}.time + obj.prep_delay;
            end            
            
            % Repeat the acquisition object according
            % the number of TRs (or frames)
            valid_obj = repmat(valid_obj,[obj.nb_frames, 1]);

            % Get objects ordered
            obj.objects = cell([obj.nb_frames nobj]);
            obj.rf_pulses = cell([obj.nb_frames nobj]);
            obj.gradients = cell([obj.nb_frames nobj]);
            for i=1:obj.nb_frames*nobj
                obj.objects{i} = valid_obj{i};
                if strcmp(class(valid_obj{i}),'RF')
                    obj.rf_pulses{i} = valid_obj{i};
                elseif strcmp(class(valid_obj{i}),'GR')
                    obj.gradients{i} = valid_obj{i};
                end
            end

            % Create timing object based on RF and GR durations
            times = zeros([obj.nb_frames nobj]);
            steps = zeros([obj.nb_frames nobj]);
            for i=1:obj.nb_frames
                for j=1:nobj
                    times(i,j) = obj.TR*(i-1) + obj.objects{i,j}.time + ...
                                 obj.objects{i,j}.dur;
                    steps(i,j) = obj.TR*(i~=1)*(j==1) + obj.objects{i,j}.dur;
                end
            end
            times = reshape(times',[1 obj.nb_frames*nobj]);
            steps = reshape(steps',[1 obj.nb_frames*nobj]);
            obj.timing = struct('times',times,'dur',steps); 

            % Reshape acquistion objects
            obj.objects = reshape(obj.objects',[1 obj.nb_frames*nobj]);
            obj.rf_pulses = reshape(obj.rf_pulses',[1 obj.nb_frames*nobj]);
            obj.gradients = reshape(obj.gradients',[1 obj.nb_frames*nobj]);

        end

    end

end
