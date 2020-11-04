classdef Sequence
    properties
        objects
        timing
        rf_pulses
        gradients        
        preparation
        acquisition
    end
    
    methods
      function obj = Sequence(varargin) 
            % Default arguments
            defapi = struct('preparation',[],'acquisition',[]);

            % Parse inputs
            api = parseinputs(defapi,[],varargin{:});
            objects = fieldnames(api);
            for i=1:numel(objects)
                obj.(objects{i}) = api.(objects{i});
            end

            % Concatenate objects
            acq_objs = obj.acquisition.objects;
            obj.objects = obj.preparation.objects;
            obj.objects(end+1:end+numel(acq_objs)) = acq_objs;            
            
            % Concatenate RF pulses
            acq_rf = obj.acquisition.rf_pulses;
            obj.rf_pulses = obj.preparation.rf_pulses;
            obj.rf_pulses(end+1:end+numel(acq_rf)) = acq_rf;

            % Concatenate GR pulses
            acq_gr = obj.acquisition.gradients;
            obj.gradients = obj.preparation.gradients;
            obj.gradients(end+1:end+numel(acq_gr)) = acq_gr;
            
            % Concatenate timings
            times = [0 horzcat(obj.preparation.timing.times,...
                            obj.acquisition.timing.times)];
            steps = [times(2) (times(3:end)-times(2:end-1))];                          
            obj.timing = struct('times',times,'dur',steps);
                          
      end
    end

end